import 'package:flutter/material.dart';

import 'zbus_data.dart';
import 'zbus_domain.dart';
import 'zbus_fixtures.dart';
import 'zbus_pages.dart';
import 'zbus_theme.dart';
import 'zbus_widgets.dart';

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

class ZBusShell extends StatefulWidget {
  const ZBusShell({super.key});
  @override
  State<ZBusShell> createState() => _ZBusShellState();
}

class _ZBusShellState extends State<ZBusShell>
    with SingleTickerProviderStateMixin {
  ZRole? role;
  ZPage page = ZPage.dashboard;
  TripRecord selectedTrip = trips[2];
  String chosenOrigin = stops[0], chosenDestination = stops[2];
  ReservationRecord? selectedReservation;
  late final ReservationLedger reservationLedger = ReservationLedger(
    initialReservations: createInitialReservations(),
  );
  bool drawerOpen = false;
  bool tripStarted = false;
  bool scanned = false;

  late final AnimationController pageTransitionController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  late final Animation<double> pageOpacity = CurvedAnimation(
    parent: pageTransitionController,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> pageOffset = Tween<Offset>(
    begin: const Offset(0, .015),
    end: Offset.zero,
  ).animate(pageOpacity);

  @override
  void dispose() {
    pageTransitionController.dispose();
    super.dispose();
  }

  void animatePageChange() {
    if (MediaQuery.disableAnimationsOf(context)) {
      pageTransitionController.value = 1;
    } else {
      pageTransitionController.forward(from: 0);
    }
  }

  List<ZPage> get nav => switch (role) {
    ZRole.admin => [
      ZPage.dashboard,
      ZPage.staff,
      ZPage.permissions,
      ZPage.routes,
      ZPage.stops,
      ZPage.schedules,
      ZPage.vehicles,
      ZPage.assignments,
      ZPage.reports,
      ZPage.profile,
      ZPage.states,
    ],
    ZRole.passenger => [ZPage.search, ZPage.reservations, ZPage.profile],
    ZRole.driver => [ZPage.driverDay, ZPage.checkIn, ZPage.profile],
    null => [],
  };
  void go(ZPage destination) {
    setState(() {
      page = destination;
      drawerOpen = false;
    });
    animatePageChange();
  }

  void login(ZRole newRole) => setState(() {
    role = newRole;
    page = switch (newRole) {
      ZRole.admin => ZPage.dashboard,
      ZRole.passenger => ZPage.search,
      ZRole.driver => ZPage.driverDay,
    };
  });
  void logout() => setState(() {
    role = null;
    page = ZPage.dashboard;
    drawerOpen = false;
  });
  void selectTrip(TripRecord trip, String from, String to) {
    setState(() {
      selectedTrip = trip;
      chosenOrigin = from;
      chosenDestination = to;
      page = ZPage.seats;
    });
    animatePageChange();
  }

  void book(int seats, String from, String to) {
    setState(() {
      selectedReservation = reservationLedger.book(
        trip: selectedTrip,
        origin: from,
        destination: to,
        seats: seats,
      );
      page = ZPage.confirmation;
    });
    animatePageChange();
  }

  void cancel(ReservationRecord reservation) => setState(() {
    final cancelled = reservationLedger.cancel(reservation.id);
    if (selectedReservation?.id == cancelled.id) {
      selectedReservation = cancelled;
    }
  });
  void selectReservation(ReservationRecord reservation) {
    setState(() {
      selectedReservation = reservation;
      page = ZPage.confirmation;
    });
    animatePageChange();
  }

  void startTrip() {
    setState(() {
      tripStarted = true;
      page = ZPage.driverTrip;
    });
    animatePageChange();
  }

  void closeTrip() {
    setState(() => page = ZPage.completion);
    animatePageChange();
  }

  @override
  Widget build(BuildContext context) {
    if (role == null) return _Login(onLogin: login);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final desktop = screenWidth >= 1080;
    final mobile = screenWidth < 700;
    final pages = ZPages(
      page: page,
      role: role!,
      selectedTrip: selectedTrip,
      initialOrigin: chosenOrigin,
      initialDestination: chosenDestination,
      selectedReservation: selectedReservation,
      reservations: reservationLedger.reservations,
      availableSeats: reservationLedger.availableSeats,
      tripStarted: tripStarted,
      scanned: scanned,
      go: go,
      selectTrip: selectTrip,
      book: book,
      cancel: cancel,
      selectReservation: selectReservation,
      onStart: startTrip,
      onClose: closeTrip,
      onScan: () => setState(() {
        scanned = true;
      }),
    );
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (desktop)
              SizedBox(
                width: 264,
                child: _SideNav(
                  role: role!,
                  page: page,
                  nav: nav,
                  go: go,
                  logout: logout,
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    role: role!,
                    page: page,
                    desktop: desktop,
                    onMenu: () => setState(() => drawerOpen = !drawerOpen),
                    go: go,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        FadeTransition(
                          opacity: pageOpacity,
                          child: SlideTransition(
                            position: pageOffset,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                mobile ? 20 : 42,
                                mobile ? 28 : 44,
                                mobile ? 20 : 50,
                                100,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1360,
                                  ),
                                  child: pages,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (drawerOpen && !desktop)
                          Positioned.fill(
                            child: Container(
                              color: ZColors.bg,
                              child: _SideNav(
                                role: role!,
                                page: page,
                                nav: nav,
                                go: go,
                                logout: logout,
                                mobile: true,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (mobile && !drawerOpen)
                    _BottomNav(
                      role: role!,
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
    required this.role,
    required this.page,
    required this.desktop,
    required this.onMenu,
    required this.go,
  });
  final ZRole role;
  final ZPage page;
  final bool desktop;
  final VoidCallback onMenu;
  final ValueChanged<ZPage> go;
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
          IconButton(onPressed: onMenu, icon: const Icon(Icons.menu, size: 20)),
          const SizedBox(width: 5),
          const _Brand(small: true),
        ] else
          ZLabel('MUT / NONG CHOK NETWORK'),
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
          ZLabel('OPERATING', color: ZColors.ink),
          const SizedBox(width: 27),
        ],
        InkWell(
          onTap: () => go(ZPage.profile),
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
                ZLabel(switch (role) {
                  ZRole.admin => 'OPERATIONS',
                  ZRole.passenger => 'PASSENGER',
                  ZRole.driver => 'DRIVER',
                }, color: ZColors.ink),
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
    required this.role,
    required this.page,
    required this.nav,
    required this.go,
    required this.logout,
    this.mobile = false,
  });
  final ZRole role;
  final ZPage page;
  final List<ZPage> nav;
  final ValueChanged<ZPage> go;
  final VoidCallback logout;
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
          const SizedBox(height: 23),
          const ZRule(),
          const SizedBox(height: 31),
        ],
        ZLabel(switch (role) {
          ZRole.admin => 'CONTROL ROOM / 01',
          ZRole.passenger => 'PASSENGER / 02',
          ZRole.driver => 'DRIVER / 03',
        }, color: ZColors.accent),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(
            children: [
              for (final entry in nav.asMap().entries)
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: logout,
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
        const SizedBox(height: 9),
        const ZRule(),
        const SizedBox(height: 15),
        ZLabel('ZBUS / DESIGNED FOR THE JOURNEY'),
      ],
    ),
  );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.role,
    required this.page,
    required this.go,
    required this.onMenu,
  });
  final ZRole role;
  final ZPage page;
  final ValueChanged<ZPage> go;
  final VoidCallback onMenu;
  @override
  Widget build(BuildContext context) {
    final items = switch (role) {
      ZRole.admin => [ZPage.dashboard, ZPage.schedules, ZPage.reports],
      ZRole.passenger => [ZPage.search, ZPage.reservations, ZPage.profile],
      ZRole.driver => [ZPage.driverDay, ZPage.checkIn, ZPage.profile],
    };
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: ZColors.bg,
        border: Border(top: BorderSide(color: ZColors.line)),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: InkWell(
                onTap: () => go(item),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        switch (item) {
                          ZPage.dashboard => Icons.grid_view_outlined,
                          ZPage.schedules => Icons.schedule,
                          ZPage.reports => Icons.bar_chart,
                          ZPage.search => Icons.search,
                          ZPage.reservations =>
                            Icons.confirmation_number_outlined,
                          ZPage.driverDay => Icons.route,
                          ZPage.checkIn => Icons.qr_code_scanner,
                          _ => Icons.person_outline,
                        },
                        size: 20,
                        color: page == item ? ZColors.ink : ZColors.muted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label.toUpperCase(),
                        style: ZTheme.mono(
                          8,
                          color: page == item ? ZColors.ink : ZColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: InkWell(
              onTap: onMenu,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu, size: 20, color: ZColors.muted),
                    const SizedBox(height: 4),
                    Text('MORE', style: ZTheme.mono(8)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Login extends StatefulWidget {
  const _Login({required this.onLogin});
  final ValueChanged<ZRole> onLogin;
  @override
  State<_Login> createState() => _LoginState();
}

class _LoginState extends State<_Login> {
  ZRole selected = ZRole.passenger;
  bool remember = true;
  final email = TextEditingController(text: '');
  final password = TextEditingController();
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 850;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (!mobile)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(52),
                  decoration: const BoxDecoration(
                    color: ZColors.surface,
                    border: Border(right: BorderSide(color: ZColors.line)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Brand(),
                      const Spacer(),
                      ZLabel(
                        'MAHANAKORN UNIVERSITY OF TECHNOLOGY',
                        color: ZColors.accent,
                      ),
                      const SizedBox(height: 25),
                      Text('THE CITY,\nCONNECTED.', style: ZTheme.display(92)),
                      const SizedBox(height: 28),
                      const ZRule(),
                      const SizedBox(height: 22),
                      const Text(
                        'Reliable rides across Nong Chok. One network for the people who move it.',
                        style: TextStyle(
                          color: ZColors.muted,
                          fontSize: 17,
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                      ZLabel('01 / PLAN    02 / RIDE    03 / ARRIVE'),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(mobile ? 25 : 64),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (mobile) ...[
                          const _Brand(),
                          const SizedBox(height: 90),
                        ],
                        ZLabel('MEMBER ACCESS / ZBUS', color: ZColors.accent),
                        const SizedBox(height: 20),
                        Text(
                          'WELCOME\nABOARD.',
                          style: ZTheme.display(mobile ? 66 : 76),
                        ),
                        const SizedBox(height: 19),
                        const Text(
                          'Sign in to manage the network or find your next ride.',
                          style: TextStyle(color: ZColors.muted, height: 1.5),
                        ),
                        const SizedBox(height: 36),
                        const ZRule(),
                        const SizedBox(height: 25),
                        const ZLabel('VIEW AS'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            for (final r in ZRole.values)
                              ChoiceChip(
                                label: Text(
                                  r.name.toUpperCase(),
                                  style: ZTheme.mono(
                                    10,
                                    color: selected == r
                                        ? ZColors.bg
                                        : ZColors.ink,
                                  ),
                                ),
                                selected: selected == r,
                                onSelected: (_) => setState(() => selected = r),
                                selectedColor: ZColors.ink,
                                backgroundColor: ZColors.surface,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                  side: BorderSide(color: ZColors.line),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 23),
                        ZField(
                          'Institutional email',
                          controller: email,
                          hint: 'Enter Email',
                        ),
                        const SizedBox(height: 19),
                        ZField(
                          'Password',
                          controller: password,
                          hint: 'Enter password',
                          obscure: true,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: remember,
                              onChanged: (v) =>
                                  setState(() => remember = v ?? false),
                              activeColor: ZColors.ink,
                              checkColor: ZColors.bg,
                            ),
                            const Text(
                              'Keep me signed in',
                              style: TextStyle(
                                color: ZColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ZButton(
                            'Enter ZBus',
                            onPressed: () => widget.onLogin(selected),
                            icon: Icons.arrow_forward,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const ZNotice(
                          'Mockup access',
                          'Choose a role to explore its screens. No credentials are required for this design prototype.',
                          color: ZColors.success,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
