import 'package:flutter/material.dart';

import '../presentation/shared/design_system.dart';
import '../presentation/shared/page_host.dart';
import 'app_page.dart';

class ZBusApp extends StatelessWidget {
  const ZBusApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ZBus Transport',
    debugShowCheckedModeBanner: false,
    theme: ZTheme.dark,
    home: const ZBusShell(),
  );
}

/// Navigation is the only state in the scaffold. Business actions stay disabled
/// until the application layer supplies their callbacks; there is no demo login.
///
/// The chrome (brand, top bar, numbered side navigation, bottom bar and the
/// fade/slide page transition) is presentation only and carries no domain state.
class ZBusShell extends StatefulWidget {
  const ZBusShell({super.key});
  @override
  State<ZBusShell> createState() => _ZBusShellState();
}

class _ZBusShellState extends State<ZBusShell>
    with SingleTickerProviderStateMixin {
  AppPage page = AppPage.booking;
  bool drawerOpen = false;

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

  @override
  void dispose() {
    transition.dispose();
    super.dispose();
  }

  void go(AppPage destination) {
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

  @override
  Widget build(BuildContext context) {
    // Authentication is a full-bleed surface in the reference design, so it is
    // hosted outside the application chrome.
    if (page == AppPage.login || page == AppPage.register) {
      return Scaffold(body: SafeArea(child: page.screen));
    }
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
                  page: page,
                  go: go,
                  onSignOut: () => go(AppPage.login),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    page: page,
                    desktop: desktop,
                    onMenu: () => setState(() => drawerOpen = !drawerOpen),
                    go: go,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        FadeTransition(
                          opacity: fade,
                          child: SlideTransition(
                            position: slide,
                            child: PageHost(child: page.screen),
                          ),
                        ),
                        if (drawerOpen && !desktop)
                          Positioned.fill(
                            child: Container(
                              color: ZColors.bg,
                              child: _SideNav(
                                page: page,
                                go: go,
                                mobile: true,
                                onSignOut: () => go(AppPage.login),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (mobile && !drawerOpen)
                    _BottomNav(
                      page: page,
                      go: go,
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
    required this.onMenu,
    required this.go,
  });
  final AppPage page;
  final bool desktop;
  final VoidCallback onMenu;
  final ValueChanged<AppPage> go;
  @override
  Widget build(BuildContext context) => Container(
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
              const CircleAvatar(
                radius: 16,
                backgroundColor: ZColors.surface2,
                child: Text(
                  'Z',
                  style: TextStyle(fontSize: 14, color: ZColors.ink),
                ),
              ),
              if (MediaQuery.sizeOf(context).width >= 700) ...[
                const SizedBox(width: 9),
                ZLabel(page.group.toUpperCase(), color: ZColors.ink),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.page,
    required this.go,
    required this.onSignOut,
    this.mobile = false,
  });
  final AppPage page;
  final ValueChanged<AppPage> go;
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
        const ZLabel('ZBUS / DESIGNED FOR THE JOURNEY'),
      ],
    ),
  );

  Widget _section(String group, String label) {
    final entries = AppPage.values
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
    required this.onMenu,
  });
  final AppPage page;
  final ValueChanged<AppPage> go;
  final VoidCallback onMenu;
  static const _shortcuts = [
    AppPage.booking,
    AppPage.bookings,
    AppPage.driverSchedule,
    AppPage.user,
    AppPage.reports,
  ];
  @override
  Widget build(BuildContext context) => Container(
    height: 72,
    decoration: const BoxDecoration(
      color: ZColors.bg,
      border: Border(top: BorderSide(color: ZColors.line)),
    ),
    child: Row(
      children: [
        for (final item in _shortcuts)
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