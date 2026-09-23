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
  SessionUser? session;
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
  final List<BookingDraftTrip> bookingDraft = [];

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

  List<ZPage> get nav {
    final ordered = [
      ZPage.dashboard,
      ZPage.departments,
      ZPage.positions,
      ZPage.users,
      ZPage.staff,
      ZPage.permissions,
      ZPage.routes,
      ZPage.stops,
      ZPage.schedules,
      ZPage.vehicles,
      ZPage.assignments,
      ZPage.drivers,
      ZPage.reports,
      ZPage.states,
      ZPage.search,
      ZPage.reservations,
      ZPage.driverDay,
      ZPage.checkIn,
      ZPage.profile,
    ];
    return ordered
        .where(
          (candidate) => session?.allowedPages.contains(candidate) ?? false,
        )
        .toList();
  }

  void go(ZPage destination) {
    setState(() {
      page = destination;
      drawerOpen = false;
    });
    animatePageChange();
  }

  void login(SessionUser user) => setState(() {
    session = user;
    page = switch (user.role) {
      ZRole.admin => ZPage.dashboard,
      ZRole.passenger => ZPage.search,
      ZRole.driver => ZPage.driverDay,
    };
  });
  void logout() => setState(() {
    session = null;
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
      bookingDraft.add(
        BookingDraftTrip(
          trip: selectedTrip,
          origin: from,
          destination: to,
          seats: seats,
        ),
      );
      page = ZPage.search;
    });
    animatePageChange();
  }

  void checkout() {
    setState(() {
      final booked = reservationLedger.bookGroup(bookingDraft);
      selectedReservation = booked.first;
      bookingDraft.clear();
      page = ZPage.confirmation;
    });
    animatePageChange();
  }

  void cancel(ReservationRecord reservation) => setState(() {
    final cancelled = reservationLedger.cancel(reservation.detailId);
    if (selectedReservation?.detailId == cancelled.detailId) {
      selectedReservation = cancelled;
    }
  });
  void cancelBooking(String bookingId) => setState(() {
    final cancelled = reservationLedger.cancelBooking(bookingId);
    if (selectedReservation?.id == bookingId) {
      selectedReservation = cancelled.first;
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
    if (session == null) return _Login(onLogin: login);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final desktop = screenWidth >= 1080;
    final mobile = screenWidth < 700;
    final pages = ZPages(
      page: page,
      role: session!.role,
      selectedTrip: selectedTrip,
      initialOrigin: chosenOrigin,
      initialDestination: chosenDestination,
      selectedReservation: selectedReservation,
      reservations: reservationLedger.reservations,
      bookingDraft: List.unmodifiable(bookingDraft),
      availableSeats: reservationLedger.availableSeats,
      tripStarted: tripStarted,
      scanned: scanned,
      go: go,
      selectTrip: selectTrip,
      book: book,
      cancel: cancel,
      cancelBooking: cancelBooking,
      checkout: checkout,
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
                  role: session!.role,
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
                    role: session!.role,
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
                                role: session!.role,
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
                      role: session!.role,
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

  static const bookingPages = {
    ZPage.search,
    ZPage.seats,
    ZPage.bookingCart,
    ZPage.confirmation,
    ZPage.reservations,
    ZPage.driverDay,
    ZPage.driverTrip,
    ZPage.checkIn,
    ZPage.completion,
    ZPage.profile,
  };

  static const statisticPages = {ZPage.reports};

  @override
  Widget build(BuildContext context) {
    final booking = nav.where(bookingPages.contains).toList();
    final management = nav
        .where(
          (item) =>
              !bookingPages.contains(item) && !statisticPages.contains(item),
        )
        .toList();
    final statistics = nav.where(statisticPages.contains).toList();
    final itemNumbers = {
      for (final entry in nav.asMap().entries) entry.value: entry.key + 1,
    };

    Widget section(String title, List<ZPage> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZLabel(title, color: ZColors.accent),
        const SizedBox(height: 8),
        for (final item in items)
          Column(
            children: [
              InkWell(
                onTap: () => go(item),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 9,
                  ),
                  color: page == item ? ZColors.surface2 : Colors.transparent,
                  child: Row(
                    children: [
                      Text(
                        itemNumbers[item]!.toString().padLeft(2, '0'),
                        style: ZTheme.mono(
                          10,
                          color: page == item ? ZColors.accent : ZColors.muted,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          item.label.toUpperCase(),
                          style: ZTheme.mono(
                            11,
                            color: page == item ? ZColors.ink : ZColors.muted,
                          ),
                        ),
                      ),
                      if (page == item)
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
        const SizedBox(height: 25),
      ],
    );

    return Container(
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
          Expanded(
            child: ListView(
              children: [
                section('01 / BOOKING & ACCOUNT', booking),
                section('02 / MANAGEMENT', management),
                section('03 / STATISTICS', statistics),
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
  final ValueChanged<SessionUser> onLogin;
  @override
  State<_Login> createState() => _LoginState();
}

class _LoginState extends State<_Login> {
  bool remember = true;
  bool registering = false;
  final email = TextEditingController(text: '');
  final password = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  String registrationDepartment = 'D0007 / Computer Science';
  String registrationPosition = 'P0002 / Student';
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    firstName.dispose();
    lastName.dispose();
    super.dispose();
  }

  SessionUser sessionForEmail() {
    final value = email.text.trim().toLowerCase();
    if (value == 'admin@mut.edu') {
      return SessionUser(
        name: 'Admin System',
        email: 'admin@mut.edu',
        position: 'Admin',
        role: ZRole.admin,
        allowedPages: ZPage.values.toSet(),
      );
    }
    if (value == 'driver@mut.edu') {
      return const SessionUser(
        name: 'Somchai Jaidee',
        email: 'driver@mut.edu',
        position: 'Driver',
        role: ZRole.driver,
        allowedPages: {
          ZPage.search,
          ZPage.reservations,
          ZPage.driverDay,
          ZPage.driverTrip,
          ZPage.checkIn,
          ZPage.completion,
          ZPage.profile,
        },
      );
    }
    return SessionUser(
      name: registering && firstName.text.trim().isNotEmpty
          ? '${firstName.text.trim()} ${lastName.text.trim()}'.trim()
          : 'John User',
      email: value.isEmpty ? 'student@mut.edu' : value,
      position: 'Student',
      role: ZRole.passenger,
      allowedPages: ZPage.values.toSet(),
    );
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
                        if (registering) ...[
                          ZField(
                            'First name',
                            controller: firstName,
                            hint: 'First name',
                          ),
                          const SizedBox(height: 19),
                          ZField(
                            'Last name',
                            controller: lastName,
                            hint: 'Last name',
                          ),
                          const SizedBox(height: 19),
                          ZSelect(
                            'Department ID',
                            value: registrationDepartment,
                            items: const [
                              'D0005 / Staff',
                              'D0006 / Civil Engineering',
                              'D0007 / Computer Science',
                              'D0008 / Multimedia',
                              'D0009 / Architecture',
                              'D0010 / Business',
                            ],
                            onChanged: (value) => setState(() {
                              registrationDepartment =
                                  value ?? registrationDepartment;
                            }),
                          ),
                          const SizedBox(height: 19),
                          ZSelect(
                            'Position ID',
                            value: registrationPosition,
                            items: const [
                              'P0002 / Student',
                              'P0003 / Teaching Assistant',
                              'P0004 / Teacher',
                              'P0010 / Guest',
                            ],
                            onChanged: (value) => setState(() {
                              registrationPosition =
                                  value ?? registrationPosition;
                            }),
                          ),
                          const SizedBox(height: 19),
                        ],
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
                            registering ? 'Create account' : 'Enter ZBus',
                            onPressed: () => widget.onLogin(sessionForEmail()),
                            icon: Icons.arrow_forward,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ZButton(
                            registering ? 'Back to sign in' : 'Register',
                            secondary: true,
                            onPressed: () => setState(() {
                              registering = !registering;
                            }),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const ZNotice(
                          'Permission-based access',
                          'Use admin@mut.edu or driver@mut.edu to preview those positions. Other emails use Student access. No password is required in this prototype.',
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
