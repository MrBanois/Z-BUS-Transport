import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../presentation/shared/design_system.dart';
import '../presentation/shared/page_host.dart';
import 'account_controller.dart';
import 'account_host.dart';
import 'app_page.dart';
import 'auth_controller.dart';
import 'auth_gate.dart';
import 'crud_controller.dart';
import 'crud_controllers.dart';
import 'crud_host.dart';

class ZBusApp extends StatelessWidget {
  const ZBusApp({super.key, this.auth, this.account, this.crud});

  /// Injectable so a test can supply a controller backed by a fake repository.
  /// Omitting it builds a controller wired to the real FastAPI server.
  final AuthController? auth;

  /// The My account screen's state. Injectable for the same reason as [auth];
  /// when omitted the shell creates one against the real server.
  final AccountController? account;

  /// The four management screens' state, keyed by page. Injectable for the same
  /// reason; when omitted the shell creates one of each against the real server.
  ///
  /// Keyed rather than passed as four separate parameters because the set of
  /// management pages is decided by the permission mask, and a caller injecting
  /// stubs should not have to know the whole set.
  final Map<AppPage, CrudController<Object>>? crud;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ZBus Transport',
    debugShowCheckedModeBanner: false,
    theme: ZTheme.dark,
    home: ZBusShell(
      auth: auth ?? AuthController(),
      account: account ?? AccountController(),
      crud: crud,
    ),
  );
}

/// Navigation is the only state in the scaffold. Feature pages keep their
/// callbacks disabled until the application layer supplies them.
///
/// The chrome (brand, top bar, numbered side navigation, bottom bar and the
/// fade/slide page transition) is presentation only and carries no domain
/// state. Which page may open at all is decided by [AuthController] via
/// [AppPage.isAllowed].
class ZBusShell extends StatefulWidget {
  const ZBusShell({super.key, required this.auth, this.account, this.crud});
  final AuthController auth;
  final AccountController? account;
  final Map<AppPage, CrudController<Object>>? crud;
  @override
  State<ZBusShell> createState() => _ZBusShellState();
}

class _ZBusShellState extends State<ZBusShell>
    with SingleTickerProviderStateMixin {
  /// Starts on the sign-in surface. [AuthGate] redirects once a session exists.
  AppPage page = AppPage.login;
  bool drawerOpen = false;

  /// Owned here rather than by the account screen, because the record outlives
  /// the page: navigating away and back must not re-fetch it.
  late final AccountController _account =
      widget.account ?? AccountController();

  /// One controller per management screen, created lazily and kept for the life
  /// of the session.
  ///
  /// Created lazily because the shell also renders the login surface: building
  /// four controllers, and the repositories behind them, for a user who has not
  /// signed in yet would be work whose result is never shown. Kept rather than
  /// rebuilt because a list should not re-fetch every time the page is revisited,
  /// which is the same reason [_account] is held.
  final Map<AppPage, CrudController<Object>> _crud = {};

  /// Resolve the controller for a management page, building it the first time.
  ///
  /// A page outside the management set has no controller, and [crudFor] returns
  /// null for it rather than building one nothing would use.
  CrudController<Object>? crudFor(AppPage page) {
    final existing = _crud[page];
    if (existing != null) return existing;
    // Typed as CrudController<Object> rather than left to the switch: the four
    // controllers differ in their row type, so inference lands on the shared
    // base ChangeNotifier and loses the methods callers need.
    final CrudController<Object>? created = switch (page) {
      AppPage.department => DepartmentController(),
      AppPage.position => PositionController(),
      AppPage.user => UserController(),
      AppPage.employee => EmployeeController(),
      _ => null,
    };
    if (created == null) return null;
    return _crud[page] = created;
  }

  late final AnimationController transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  late final Animation<double> fade = CurvedAnimation(
    parent: transition,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> slide = Tween<Offset>(
    begin: const Offset(0, .015),
    end: Offset.zero,
  ).animate(fade);

  /// Controllers the caller supplied.
  Map<AppPage, CrudController<Object>> get _injected =>
      widget.crud ?? const {};

  @override
  void initState() {
    super.initState();
    // Seeded up front so [crudFor] hands an injected controller straight back
    // instead of building a second one for the same page.
    _crud.addAll(_injected);
  }

  @override
  void dispose() {
    transition.dispose();
    _account.dispose();
    // The shell created these, so the shell frees them. Disposing an injected
    // controller would be wrong: the caller that passed it in still holds it.
    final injected = _injected;
    for (final entry in _crud.entries) {
      if (!identical(injected[entry.key], entry.value)) entry.value.dispose();
    }
    super.dispose();
  }

  /// Open [destination], unless the current session forbids it.
  void go(AppPage destination) {
    if (!destination.isAllowed(widget.auth.session)) return;
    if (destination == page) return;
    setState(() {
      page = destination;
      drawerOpen = false;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      transition.value = 1;
    } else {
      transition.forward(from: 0);
    }
  }

  void signOut() {
    widget.auth.signOut();
    // The record belongs to the member who just left: holding it would show the
    // next sign-in's page briefly stale, or worse, let a save land on the old
    // row if the next member shares no id.
    _account.reset();
    // The management lists are not cleared. They are reference data rather than
    // anything personal, and every one of them is behind a permission bit that
    // the next session is re-checked against — so an open dialog belongs to the
    // member who left, but a cached list of departments does not. The lists are
    // re-fetched on the next visit anyway, via `load(force: true)` after a write
    // and the host's own bootstrap.
    for (final controller in _crud.values) {
      if (controller.open) controller.close();
    }
    setState(() {
      page = AppPage.login;
      drawerOpen = false;
    });
    transition.value = 1;
  }

  @override
  Widget build(BuildContext context) => AuthGate(
    auth: widget.auth,
    builder: (session) {
      // No session means the sign-in surface, hosted outside the chrome: the
      // reference design treats authentication as a full-bleed page.
      if (session == null) {
        return Scaffold(body: SafeArea(child: AuthSurface(auth: widget.auth)));
      }
      return _chrome(session);
    },
  );

  Widget _chrome(Session session) {
    // The navigation only ever offers pages this session may open, so a denied
    // page is unreachable rather than merely hidden behind an error. [account]
    // has no permission bit and is always allowed, so this is never empty.
    final reachable = AppPage.values
        .where((p) => p.isAllowed(session) && p.requiresAuth)
        .toList(growable: false);

    // Resolved during build rather than corrected in a post-frame callback: the
    // page to show is a pure function of the session, so there is nothing to
    // assign and no frame with a stale page.
    final shown = reachable.contains(page) ? page : reachable.first;

    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 1080;
    final mobile = width < 700;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (desktop)
              SizedBox(
                width: 264,
                child: _SideNav(
                  page: shown,
                  go: go,
                  reachable: reachable,
                  session: session,
                  onSignOut: signOut,
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    page: shown,
                    desktop: desktop,
                    session: session,
                    onMenu: () => setState(() => drawerOpen = !drawerOpen),
                    go: go,
                    onSignOut: signOut,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        FadeTransition(
                          opacity: fade,
                          child: SlideTransition(
                            position: slide,
                            child: PageHost(child: _screen(shown, session)),
                          ),
                        ),
                        if (drawerOpen && !desktop)
                          Positioned.fill(
                            child: Container(
                              color: ZColors.bg,
                              child: _SideNav(
                                page: shown,
                                go: go,
                                reachable: reachable,
                                session: session,
                                mobile: true,
                                onSignOut: signOut,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (mobile && !drawerOpen)
                    _BottomNav(
                      page: shown,
                      go: go,
                      reachable: reachable,
                      onMenu: () => setState(() => drawerOpen = true),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The pages that cannot be built from [AppPage.screen] alone.
  ///
  /// `AppPage.screen` stays a parameterless getter because every other page is
  /// still a static mockup with no data behind it. Each host here is where its
  /// page gets its records and its callbacks, so the exceptions are visible in
  /// this switch rather than hidden inside the enum.
  ///
  /// A management page whose controller failed to resolve falls back to
  /// [AppPage.screen]: a blank shell is worse than the mockup, and this cannot
  /// happen for the four pages named below, which [crudFor] always builds.
  Widget _screen(AppPage page, Session session) => switch (page) {
    AppPage.account => AccountHost(controller: _account, session: session),
    AppPage.department => DepartmentCrudHost(
      controller: crudFor(AppPage.department)! as DepartmentController,
    ),
    AppPage.position => PositionCrudHost(
      controller: crudFor(AppPage.position)! as PositionController,
    ),
    AppPage.user => AccountCrudHost(
      controller: crudFor(AppPage.user)! as UserController,
      staffOnly: false,
    ),
    AppPage.employee => AccountCrudHost(
      controller: crudFor(AppPage.employee)! as UserController,
      staffOnly: true,
    ),
    _ => page.screen,
  };
}

/// Group metadata for the navigation chrome. Labels carry the section index so
/// the sidebar keeps the numbered editorial rhythm of the reference design.
const _navGroups = <String, ({String label, IconData icon})>{
  'User': (label: '01 / USER', icon: Icons.person_outline),
  'Driver': (label: '02 / DRIVER', icon: Icons.route),
  'Management': (label: '03 / MANAGEMENT', icon: Icons.people_outline),
  'Route': (label: '04 / ROUTE', icon: Icons.alt_route),
  'Statistic': (label: '05 / STATISTIC', icon: Icons.bar_chart),
};

class _Brand extends StatelessWidget {
  const _Brand({this.small = false});
  final bool small;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 13,
        height: 13,
        decoration: const BoxDecoration(
          color: ZColors.accent,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 9),
      Text('ZBUS', style: ZTheme.display(small ? 24 : 30)),
      const SizedBox(width: 7),
      Text('TRANSPORT', style: ZTheme.mono(8, color: ZColors.ink)),
    ],
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.page,
    required this.desktop,
    required this.session,
    required this.onMenu,
    required this.go,
    required this.onSignOut,
  });
  final AppPage page;
  final bool desktop;
  final Session session;
  final VoidCallback onMenu, onSignOut;
  final ValueChanged<AppPage> go;
  @override
  Widget build(BuildContext context) {
    final initial = session.name.isEmpty ? '?' : session.name[0].toUpperCase();
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ZColors.line)),
      ),
      child: Row(
        children: [
          if (!desktop) ...[
            ZIconAction(icon: Icons.menu, onPressed: onMenu, tooltip: 'Menu'),
            const SizedBox(width: 14),
            const _Brand(small: true),
          ] else
            const ZLabel('MUT / NONG CHOK NETWORK'),
          const Spacer(),
          if (MediaQuery.sizeOf(context).width > 850) ...[
            const ZLabel('SERVICE STATUS'),
            const SizedBox(width: 12),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: ZColors.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const ZLabel('OPERATING', color: ZColors.ink),
            const SizedBox(width: 27),
          ],
          InkWell(
            onTap: () => go(AppPage.account),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: ZColors.surface2,
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 14, color: ZColors.ink),
                  ),
                ),
                if (MediaQuery.sizeOf(context).width >= 700) ...[
                  const SizedBox(width: 9),
                  ZLabel(session.name.toUpperCase(), color: ZColors.ink),
                ],
              ],
            ),
          ),
          // Always visible: the sidebar's sign out is behind a drawer on narrow
          // viewports, so a session must never be trapped without a way out.
          const SizedBox(width: 6),
          ZIconAction(
            icon: Icons.logout,
            onPressed: onSignOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.page,
    required this.go,
    required this.reachable,
    required this.session,
    required this.onSignOut,
    this.mobile = false,
  });
  final AppPage page;
  final ValueChanged<AppPage> go;
  final List<AppPage> reachable;
  final Session session;
  final VoidCallback onSignOut;
  final bool mobile;
  @override
  Widget build(BuildContext context) => Container(
    color: ZColors.bg,
    padding: const EdgeInsets.fromLTRB(24, 25, 24, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!mobile) ...[
          const _Brand(small: true),
          const ZGap(23),
          const ZRule(),
          const ZGap(31),
        ],
        Expanded(
          child: ListView(
            children: [
              for (final group in _navGroups.entries)
                _section(group.key, group.value.label),
            ],
          ),
        ),
        const ZGap(12),
        InkWell(
          onTap: onSignOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.logout, size: 16, color: ZColors.muted),
                const SizedBox(width: 12),
                Text('SIGN OUT', style: ZTheme.mono(11)),
              ],
            ),
          ),
        ),
        const ZGap(9),
        const ZRule(),
        const ZGap(15),
        // Makes the mask auditable: the user can see how many of the 16 screens
        // their position unlocks.
        ZLabel(
          '${session.permissions.length} / 16 SCREENS GRANTED',
          color: ZColors.muted,
        ),
        const ZGap(9),
        const ZRule(),
        const ZGap(15),
        const ZLabel('ZBUS / DESIGNED FOR THE JOURNEY'),
      ],
    ),
  );

  Widget _section(String group, String label) {
    // Numbering follows the position within the *granted* entries, so a passenger
    // sees 01, 02, 03 rather than the gaps their mask denies.
    final entries = reachable
        .where((p) => p.group == group)
        .toList(growable: false);
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZLabel(label, color: ZColors.accent),
        const ZGap(8),
        for (final entry in entries.asMap().entries)
          Column(
            children: [
              InkWell(
                onTap: () => go(entry.value),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 9,
                  ),
                  color: page == entry.value
                      ? ZColors.surface2
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Text(
                        (entry.key + 1).toString().padLeft(2, '0'),
                        style: ZTheme.mono(
                          10,
                          color: page == entry.value
                              ? ZColors.accent
                              : ZColors.muted,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          entry.value.label.toUpperCase(),
                          style: ZTheme.mono(
                            11,
                            color: page == entry.value
                                ? ZColors.ink
                                : ZColors.muted,
                          ),
                        ),
                      ),
                      if (page == entry.value)
                        const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: ZColors.ink,
                        ),
                    ],
                  ),
                ),
              ),
              const ZRule(),
            ],
          ),
        const ZGap(25),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.page,
    required this.go,
    required this.reachable,
    required this.onMenu,
  });
  final AppPage page;
  final ValueChanged<AppPage> go;
  final List<AppPage> reachable;
  final VoidCallback onMenu;
  static const _shortcuts = [
    AppPage.booking,
    AppPage.bookings,
    AppPage.driverSchedule,
    AppPage.user,
    AppPage.reports,
  ];
  @override
  Widget build(BuildContext context) {
    // Only the granted shortcuts survive, so the bar never offers a dead tab.
    // [account] backs the bar when a mask unlocks none of the shortcuts.
    final items = <AppPage>[
      for (final item in _shortcuts)
        if (reachable.contains(item)) item,
    ];
    if (items.isEmpty && reachable.contains(AppPage.account)) {
      items.add(AppPage.account);
    }
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: ZColors.bg,
        border: Border(top: BorderSide(color: ZColors.line)),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(child: _item(context, item, () => go(item))),
          Expanded(
            child: InkWell(
              onTap: onMenu,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu, size: 20, color: ZColors.muted),
                  const SizedBox(height: 4),
                  Text('MORE', style: ZTheme.mono(8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, AppPage item, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _navGroups[item.group]?.icon ?? Icons.circle_outlined,
          size: 20,
          color: page == item ? ZColors.ink : ZColors.muted,
        ),
        const SizedBox(height: 4),
        Text(
          item.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ZTheme.mono(
            8,
            color: page == item ? ZColors.ink : ZColors.muted,
          ),
        ),
      ],
    ),
  );
}