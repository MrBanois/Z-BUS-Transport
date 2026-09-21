import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'zbus_data.dart';
import 'zbus_domain.dart';
import 'zbus_fixtures.dart';
import 'zbus_theme.dart';
import 'zbus_widgets.dart';

class ZPages extends StatefulWidget {
  const ZPages({
    super.key,
    required this.page,
    required this.role,
    required this.selectedTrip,
    required this.initialOrigin,
    required this.initialDestination,
    required this.selectedReservation,
    required this.reservations,
    required this.tripStarted,
    required this.scanned,
    required this.availableSeats,
    required this.go,
    required this.selectTrip,
    required this.book,
    required this.cancel,
    required this.selectReservation,
    required this.onStart,
    required this.onClose,
    required this.onScan,
  });
  final ZPage page;
  final ZRole role;
  final TripRecord selectedTrip;
  final String initialOrigin, initialDestination;
  final ReservationRecord? selectedReservation;
  final List<ReservationRecord> reservations;
  final bool tripStarted, scanned;
  final int Function(TripRecord) availableSeats;
  final ValueChanged<ZPage> go;
  final void Function(TripRecord, String, String) selectTrip;
  final void Function(int, String, String) book;
  final ValueChanged<ReservationRecord> cancel, selectReservation;
  final VoidCallback onStart, onClose, onScan;
  @override
  State<ZPages> createState() => _ZPagesState();
}

class _ZPagesState extends State<ZPages> {
  late String origin = widget.initialOrigin;
  late String destination = widget.initialDestination;
  String reservationFilter = 'Upcoming';
  String report = 'Boardings / alightings', activeStop = stops[0];
  int seatCount = 1;
  bool searched = false, loading = false, showError = false;
  final staffSearch = TextEditingController();
  final scanController = TextEditingController();
  final profileName = TextEditingController(text: 'John User');
  final profileEmail = TextEditingController(text: 'johnuser@zbus.co.th');
  final permissions = <String, Set<String>>{
    'Operations manager': {
      'Overview',
      'People',
      'Access',
      'Routes',
      'Stops',
      'Schedules',
      'Vehicles',
      'Assignments',
      'Reports',
    },
    'Dispatcher': {
      'Overview',
      'Routes',
      'Stops',
      'Schedules',
      'Vehicles',
      'Assignments',
      'Reports',
    },
    'Driver': {'My day', 'Trip detail', 'Check-in', 'Trip summary'},
    'Student': {'Find a trip', 'Reserve seats', 'My reservations'},
  };
  String permissionRole = 'Dispatcher';
  @override
  void dispose() {
    staffSearch.dispose();
    scanController.dispose();
    profileName.dispose();
    profileEmail.dispose();
    super.dispose();
  }

  bool get mobile => MediaQuery.sizeOf(context).width < 750;
  Widget header(
    String index,
    String kicker,
    String title,
    String description, {
    Widget? action,
  }) => ZPageHeader(
    index: index,
    kicker: kicker,
    title: title,
    description: description,
    action: action,
  );
  Widget gap([double h = 28]) => SizedBox(height: h);
  Widget columns(
    List<Widget> children, {
    int desktopColumns = 3,
    double spacing = 12,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final n = constraints.maxWidth < 650
          ? 1
          : constraints.maxWidth < 1050
          ? math.min(2, desktopColumns)
          : desktopColumns;
      final width = (constraints.maxWidth - spacing * (n - 1)) / n;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children
            .map((e) => SizedBox(width: width, child: e))
            .toList(),
      );
    },
  );
  Widget rowLabel(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      ZLabel(label),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ],
  );
  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: ZColors.surface2,
      behavior: SnackBarBehavior.floating,
    ),
  );
  Future<void> confirm(String title, String body, VoidCallback action) async {
    final okay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title.toUpperCase(), style: ZTheme.display(33)),
        content: Text(body, style: const TextStyle(height: 1.5)),
        actions: [
          ZButton(
            'Keep',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          ZButton('Confirm', onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (okay == true && mounted) action();
  }

  @override
  Widget build(BuildContext context) => switch (widget.page) {
    ZPage.dashboard => dashboard(),
    ZPage.staff => staffPage(),
    ZPage.permissions => permissionsPage(),
    ZPage.routes => routesPage(),
    ZPage.stops => stopsPage(),
    ZPage.schedules => schedulesPage(),
    ZPage.vehicles => vehiclesPage(),
    ZPage.assignments => assignmentsPage(),
    ZPage.search => searchPage(),
    ZPage.seats => seatsPage(),
    ZPage.confirmation => confirmationPage(),
    ZPage.reservations => reservationsPage(),
    ZPage.driverDay => driverDayPage(),
    ZPage.driverTrip => driverTripPage(),
    ZPage.checkIn => checkInPage(),
    ZPage.completion => completionPage(),
    ZPage.reports => reportsPage(),
    ZPage.profile => profilePage(),
    ZPage.states => statesPage(),
  };

  Widget dashboard() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '01',
        'CONTROL ROOM / MON 14 SEP',
        'THE NETWORK\nAT A GLANCE.',
        'A live operational picture of routes, runs, seats and service across the MUT Nong Chok shuttle network.',
        action: ZButton(
          'Build a schedule',
          onPressed: () => widget.go(ZPage.schedules),
          icon: Icons.arrow_forward,
        ),
      ),
      columns(const [
        ZStat('Trips today', '12', '8 scheduled / 3 boarding / 1 completed'),
        ZStat('Reservations', '86', '74 confirmed / 12 checked in'),
        ZStat('Available seats', '42', 'Across the next eight departures'),
        ZStat('Active routes', '03', '7 stops across Nong Chok'),
      ], desktopColumns: 4),
      gap(42),
      ZSectionTitle(
        '01 / TODAY',
        'Next departures',
        trailing: TextButton(
          onPressed: () => widget.go(ZPage.schedules),
          child: const Text('VIEW ALL →'),
        ),
      ),
      ZTable(
        headers: const ['Run', 'Departure', 'Vehicle', 'Seats', 'Status'],
        rows: trips
            .take(5)
            .map(
              (t) => ZRecord(
                title:
                    '${t.route}  /  ${routes.firstWhere((r) => r.id == t.route).name}',
                subtitle: t.id,
                fields: {
                  'Departure': t.time,
                  'Vehicle': t.plate,
                  'Seats': '${widget.availableSeats(t)} / ${t.capacity}',
                },
                status: t.status,
                onTap: () => widget.go(ZPage.schedules),
              ),
            )
            .toList(),
      ),
      gap(42),
      ZSectionTitle('02 / SIGNALS', 'Operations notes'),
      columns([
        const ZNotice(
          'Dispatch check',
          'Driver and vehicle allocations are checked for overlapping runs before a schedule is published.',
          color: ZColors.success,
        ),
        const ZNotice(
          'Capacity watch',
          'R02 at 11:00 has only two seats remaining. Passenger booking is limited by segment capacity.',
        ),
        ZPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZLabel('DEEPER VIEW'),
              gap(16),
              Text('REPORTS & FLOW', style: ZTheme.display(27)),
              gap(14),
              const Text(
                'Compare boardings, reservations and vehicle utilization.',
                style: TextStyle(color: ZColors.muted),
              ),
              gap(20),
              ZButton(
                'Open reports',
                secondary: true,
                onPressed: () => widget.go(ZPage.reports),
                icon: Icons.arrow_forward,
              ),
            ],
          ),
        ),
      ]),
    ],
  );

  Widget staffPage() {
    final filtered = staff
        .where(
          (p) => p
              .join(' ')
              .toLowerCase()
              .contains(staffSearch.text.toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          '02',
          'MASTER FILE / PEOPLE',
          'THE PEOPLE\nWHO MOVE US.',
          'Manage employees, departments and positions. Role-based access follows the employee position.',
          action: ZButton(
            'Add employee',
            onPressed: () => _employeeDialog(),
            icon: Icons.add,
          ),
        ),
        columns(const [
          ZStat('Employees', '06', 'Across transport operations'),
          ZStat('Active drivers', '04', 'Available for assignment'),
          ZStat('Departments', '01', 'Transport'),
        ]),
        gap(36),
        ZField(
          'Search employees',
          controller: staffSearch,
          hint: 'Name, ID, role or department',
          onChanged: (_) => setState(() {}),
        ),
        gap(20),
        if (filtered.isEmpty)
          const ZEmpty(
            'No matching people',
            'Try a different name, ID, or position.',
          )
        else
          ZTable(
            headers: const ['Employee', 'Position', 'Department', 'Status'],
            rows: filtered
                .map(
                  (p) => ZRecord(
                    title: p[0],
                    subtitle: p[1],
                    fields: {'Position': p[2], 'Department': p[3]},
                    status: p[4],
                    onTap: () => _employeeDialog(person: p),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Future<void> _employeeDialog({List<String>? person}) async {
    final name = TextEditingController(text: person?.first);
    String position = person?[2] ?? 'Driver';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) => AlertDialog(
          title: Text(
            person == null ? 'ADD EMPLOYEE' : 'EMPLOYEE DETAIL',
            style: ZTheme.display(35),
          ),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ZField('Full name', controller: name, hint: 'Employee name'),
                gap(20),
                ZSelect(
                  'Position',
                  value: position,
                  items: const ['Driver', 'Dispatcher', 'Operations manager'],
                  onChanged: (v) => setDialog(() => position = v ?? position),
                ),
                gap(20),
                const ZNotice(
                  'Access rule',
                  'Screen access is controlled by position in the dynamic permissions matrix.',
                  color: ZColors.success,
                ),
              ],
            ),
          ),
          actions: [
            ZButton(
              'Cancel',
              secondary: true,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ZButton(
              'Save mockup',
              onPressed: () {
                Navigator.pop(dialogContext);
                message('Employee draft saved in this prototype.');
              },
            ),
          ],
        ),
      ),
    );
    name.dispose();
  }

  Widget permissionsPage() {
    final modules = [
      'Overview',
      'People',
      'Access',
      'Routes',
      'Stops',
      'Schedules',
      'Vehicles',
      'Assignments',
      'Reports',
      'Find a trip',
      'Reserve seats',
      'My reservations',
      'My day',
      'Trip detail',
      'Check-in',
      'Trip summary',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          '03',
          'MASTER FILE / ACCESS',
          'ACCESS IS\nASSIGNED.',
          'Define which screens each position can reach. The matrix is editable at any time; privileges are never hard-coded to a fixed admin role.',
          action: ZButton(
            'Add position',
            onPressed: () =>
                message('New position draft created in this prototype.'),
            icon: Icons.add,
          ),
        ),
        const ZNotice(
          'Dynamic permissions',
          'Changes below update the mock permission matrix immediately. Real enforcement belongs to the application authorization layer.',
          color: ZColors.success,
        ),
        gap(30),
        columns(
          permissions.keys
              .map(
                (p) => InkWell(
                  onTap: () => setState(() => permissionRole = p),
                  child: ZPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZLabel(
                          'POSITION / ${p == permissionRole ? 'SELECTED' : 'OPEN'}',
                          color: p == permissionRole
                              ? ZColors.accent
                              : ZColors.muted,
                        ),
                        gap(15),
                        Text(p.toUpperCase(), style: ZTheme.display(27)),
                        gap(17),
                        Text(
                          '${permissions[p]!.length} screens enabled',
                          style: const TextStyle(color: ZColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          desktopColumns: 4,
        ),
        gap(36),
        ZSectionTitle('01 / MATRIX', '$permissionRole permissions'),
        ZPanel(
          child: Column(
            children: [
              for (final m in modules)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(m, style: const TextStyle(fontSize: 14)),
                        ),
                        Switch(
                          value: permissions[permissionRole]!.contains(m),
                          activeTrackColor: ZColors.success,
                          onChanged: (v) => setState(() {
                            if (v) {
                              permissions[permissionRole]!.add(m);
                            } else {
                              permissions[permissionRole]!.remove(m);
                            }
                          }),
                        ),
                      ],
                    ),
                    const ZRule(),
                  ],
                ),
            ],
          ),
        ),
        gap(20),
        ZButton(
          'Save permissions',
          onPressed: () =>
              message('$permissionRole permissions saved for the mockup.'),
          icon: Icons.arrow_forward,
        ),
      ],
    );
  }

  Widget routesPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '04',
        'SERVICE DESIGN / ROUTES',
        'LINES THROUGH\nNONG CHOK.',
        'Build a route from ordered stops. A stop can belong to multiple routes and can appear again on a return leg.',
        action: ZButton(
          'Create route',
          onPressed: () =>
              message('Route editor draft opened in this prototype.'),
          icon: Icons.add,
        ),
      ),
      columns(
        routes
            .map(
              (r) => ZPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ZLabel(r.id, color: ZColors.accent),
                        const Spacer(),
                        const ZStatus('Active'),
                      ],
                    ),
                    gap(25),
                    Text(r.name.toUpperCase(), style: ZTheme.display(33)),
                    gap(24),
                    const ZRule(),
                    gap(18),
                    rowLabel('Stops', r.stops.length.toString()),
                    gap(12),
                    rowLabel('Total duration', '${r.minutes} min'),
                    gap(12),
                    rowLabel('Daily runs', r.runs.toString()),
                    gap(27),
                    ZButton(
                      'View route',
                      secondary: true,
                      onPressed: () => _routeDialog(r),
                      icon: Icons.arrow_forward,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
      gap(44),
      ZSectionTitle('01 / NETWORK', 'Shared stopping points'),
      const ZNotice(
        'Route timing',
        'Total duration is derived from each consecutive stop segment. Return legs can reuse the same stop in one route.',
        color: ZColors.success,
      ),
      gap(22),
      for (final r in routes)
        ZRecord(
          title: r.name,
          subtitle: r.id,
          fields: {
            'FROM': r.stops.first,
            'TO': r.stops.last,
            'DURATION': '${r.minutes} MIN',
          },
          status: 'Active',
          onTap: () => _routeDialog(r),
        ),
    ],
  );
  Future<void> _routeDialog(RouteRecord r) async => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(r.name.toUpperCase(), style: ZTheme.display(37)),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in r.stops.asMap().entries)
                Column(
                  children: [
                    Row(
                      children: [
                        ZLabel(
                          (item.key + 1).toString().padLeft(2, '0'),
                          color: ZColors.accent,
                        ),
                        const SizedBox(width: 17),
                        Expanded(child: Text(item.value)),
                        Text(
                          item.key == 0
                              ? 'START'
                              : '+${r.segmentMinutes[item.key - 1]} MIN',
                          style: ZTheme.mono(10),
                        ),
                      ],
                    ),
                    gap(13),
                    const ZRule(),
                    gap(13),
                  ],
                ),
              gap(5),
              rowLabel('TOTAL DURATION', '${r.minutes} MIN'),
            ],
          ),
        ),
      ),
      actions: [
        ZButton('Close', secondary: true, onPressed: () => Navigator.pop(ctx)),
      ],
    ),
  );

  Widget stopsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '05',
        'MASTER FILE / STATIONS',
        'PLACES TO\nGET THERE.',
        'Every pick-up and drop-off point in the network. Reuse stops across routes and keep inactive stops out of new schedules.',
        action: ZButton(
          'Add stop',
          onPressed: () => message('Stop draft opened in this prototype.'),
          icon: Icons.add,
        ),
      ),
      columns(const [
        ZStat('Network stops', '07', 'Across three active lines'),
        ZStat('Interchanges', '03', 'Served by multiple routes'),
        ZStat('Active', '07', 'Ready for scheduling'),
      ]),
      gap(35),
      ZSectionTitle('01 / DIRECTORY', 'All stops'),
      ZTable(
        headers: const ['Stop', 'Routes', 'Type', 'Status'],
        rows: stops
            .asMap()
            .entries
            .map(
              (e) => ZRecord(
                title: e.value,
                subtitle: 'ST-${(e.key + 1).toString().padLeft(3, '0')}',
                fields: {
                  'Routes': routes
                      .where((r) => r.stops.contains(e.value))
                      .map((r) => r.id)
                      .join(' / '),
                  'Type': e.key == 0
                      ? 'Campus terminal'
                      : e.key == 1
                      ? 'Interchange'
                      : 'Street stop',
                },
                status: 'Active',
                onTap: () => message('${e.value} is active in the network.'),
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget schedulesPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '06',
        'OPERATIONS / TIMETABLE',
        'EVERY RUN\nHAS A PLACE.',
        'Plan departure times by route, then assign a driver and vehicle. Overlapping allocations must be resolved before publishing.',
        action: ZButton(
          'New departure',
          onPressed: () => _scheduleDialog(),
          icon: Icons.add,
        ),
      ),
      const ZNotice(
        'Conflict guard',
        'The same driver or vehicle cannot be assigned to overlapping runs. Route duration defines the occupied time window.',
        color: ZColors.success,
      ),
      gap(32),
      ZSectionTitle('01 / MON 14 SEP', 'Published departures'),
      ZTable(
        headers: const ['Run', 'Time', 'Driver', 'Vehicle', 'Status'],
        rows: trips
            .map(
              (t) => ZRecord(
                title:
                    '${t.route} / ${routes.firstWhere((r) => r.id == t.route).name}',
                subtitle: t.id,
                fields: {
                  'Time': '${t.time}–${t.arrival}',
                  'Driver': t.driver,
                  'Vehicle': t.plate,
                },
                status: t.status,
                onTap: () => _scheduleDialog(t: t),
              ),
            )
            .toList(),
      ),
    ],
  );
  Future<void> _scheduleDialog({TripRecord? t}) async {
    String route = t?.route ?? 'R01',
        driver = t?.driver ?? 'John Driver',
        vehicle = t?.plate ?? 'SY 2591';
    final time = TextEditingController(text: t?.time ?? '16:00');
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(
            t == null ? 'NEW DEPARTURE' : 'DEPARTURE DETAIL',
            style: ZTheme.display(34),
          ),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ZSelect(
                    'Route',
                    value: route,
                    items: routes.map((r) => r.id).toList(),
                    onChanged: (v) => update(() => route = v ?? route),
                  ),
                  gap(15),
                  ZField('Departure time', controller: time, hint: 'HH:MM'),
                  gap(15),
                  ZSelect(
                    'Driver',
                    value: driver,
                    items: const [
                      'John Driver',
                      'Jane Driver',
                      'Devid Driver',
                      'Robert Driver',
                    ],
                    onChanged: (v) => update(() => driver = v ?? driver),
                  ),
                  gap(15),
                  ZSelect(
                    'Vehicle',
                    value: vehicle,
                    items: const ['SY 2591', 'SY 2599', 'BK 1130', 'NN 5566'],
                    onChanged: (v) => update(() => vehicle = v ?? vehicle),
                  ),
                  gap(20),
                  const ZNotice(
                    'Before publishing',
                    'Check the full interval for both driver and vehicle conflicts.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ZButton(
              'Close',
              secondary: true,
              onPressed: () => Navigator.pop(ctx),
            ),
            ZButton(
              'Check & save',
              onPressed: () {
                Navigator.pop(ctx);
                message('Schedule draft checked for conflicts in the mockup.');
              },
            ),
          ],
        ),
      ),
    );
    time.dispose();
  }

  Widget vehiclesPage() {
    const vehicles = [
      ['SY 2591', 'Van', '09', '4 runs', 'In service'],
      ['SY 2599', 'Van', '09', '4 runs', 'In service'],
      ['BK 1130', 'Bus', '20', '2 runs', 'In service'],
      ['NN 5566', 'Minibus', '15', '1 run', 'In service'],
      ['CH 7788', 'Van', '09', '0 runs', 'Standby'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          '07',
          'FLEET / VEHICLES',
          'THE FLEET\nIN MOTION.',
          'Maintain vehicle type, registration, seat capacity and service state. Capacity controls what passengers can reserve.',
          action: ZButton(
            'Add vehicle',
            onPressed: () => message('Vehicle draft opened in this prototype.'),
            icon: Icons.add,
          ),
        ),
        columns(const [
          ZStat('Vehicles', '05', '4 active / 1 standby'),
          ZStat('Total seats', '62', 'Across the listed fleet'),
          ZStat('Types', '03', 'Van / minibus / bus'),
        ]),
        gap(35),
        ZSectionTitle('01 / REGISTRY', 'Vehicle directory'),
        ZTable(
          headers: const [
            'Registration',
            'Type',
            'Capacity',
            'Today',
            'Status',
          ],
          rows: vehicles
              .map(
                (v) => ZRecord(
                  title: v[0],
                  subtitle: 'ZBUS / FLEET',
                  fields: {
                    'Type': v[1],
                    'Capacity': '${v[2]} seats',
                    'Today': v[3],
                  },
                  status: v[4],
                  onTap: () => message('${v[0]} vehicle record selected.'),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget assignmentsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '08',
        'OPERATIONS / DISPATCH',
        'PUT THE RIGHT\nPEOPLE ON BOARD.',
        'Pair drivers and vehicles with published runs. The timetable remains clear when each assignment has a distinct time window.',
        action: ZButton(
          'Assign a run',
          onPressed: () => _scheduleDialog(),
          icon: Icons.add,
        ),
      ),
      columns(const [
        ZStat('Driver shifts', '04', 'For Monday 14 September'),
        ZStat('Allocated runs', '08', 'Across three routes'),
        ZStat('Conflicts', '00', 'No overlapping assignments'),
      ]),
      gap(32),
      ZSectionTitle('01 / ROSTER', 'Today’s assignments'),
      for (final driver in [
        'John Driver',
        'Jane Driver',
        'Devid Driver',
        'Robert Driver',
      ])
        ZRecord(
          title: driver,
          subtitle: 'TRANSPORT / DRIVER',
          fields: {
            'Runs': trips
                .where((t) => t.driver == driver)
                .map((t) => '${t.route} ${t.time}')
                .join('  ·  '),
            'Vehicle': trips.firstWhere((t) => t.driver == driver).plate,
          },
          status: 'Assigned',
          onTap: () => message('$driver assignment selected.'),
        ),
      gap(32),
      const ZNotice(
        'Assignment rule',
        'A driver and a vehicle may work multiple runs in one day, provided the occupied time windows do not overlap.',
        color: ZColors.success,
      ),
    ],
  );

  List<TripRecord> get matchingTrips => BookingRules.eligibleTrips(
    origin: origin,
    destination: destination,
    currentMinutes: 8 * 60 + 40,
    trips: trips,
    routes: routes,
  );

  Widget searchPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '09',
        'PASSENGER / PLAN A RIDE',
        'WHERE TO\nNEXT?',
        'Choose your boarding and destination stops. We show only runs with enough time to reserve before boarding.',
        action: const ZStatus('NETWORK OPERATING'),
      ),
      ZPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZLabel('01 / YOUR JOURNEY', color: ZColors.accent),
            gap(23),
            columns([
              ZSelect(
                'Board at',
                value: origin,
                items: stops,
                onChanged: (v) => setState(() {
                  origin = v ?? origin;
                  searched = false;
                }),
              ),
              ZSelect(
                'Get off at',
                value: destination,
                items: stops,
                onChanged: (v) => setState(() {
                  destination = v ?? destination;
                  searched = false;
                }),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ZLabel('Travel date'),
                  gap(9),
                  Container(
                    width: double.infinity,
                    height: 57,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ZColors.surface2,
                      border: Border.all(color: ZColors.line),
                    ),
                    child: const Text('MON 14 SEP 2026'),
                  ),
                ],
              ),
            ]),
            gap(22),
            ZButton(
              'Find departures',
              onPressed: () => setState(() => searched = true),
              icon: Icons.arrow_forward,
            ),
            gap(20),
            const Text(
              'Preview clock 08:40 ICT  /  Reservations close 20 minutes before arrival at your boarding stop.',
              style: TextStyle(fontSize: 12, color: ZColors.muted),
            ),
          ],
        ),
      ),
      gap(42),
      ZSectionTitle(
        '02 / RESULTS',
        searched ? 'Available departures' : 'Find your next run',
      ),
      if (!searched)
        ZEmpty(
          'Search the network',
          'Set your stops and choose Find departures to view eligible trips.',
        )
      else if (origin == destination)
        const ZNotice(
          'Choose different stops',
          'Boarding and destination must be different.',
          color: ZColors.accent,
          icon: Icons.error_outline,
        )
      else if (matchingTrips.isEmpty)
        ZEmpty(
          'No eligible trips',
          'There are no departures for that direction after the 20-minute booking cutoff.',
          action: ZButton(
            'Change stops',
            onPressed: () => setState(() => searched = false),
          ),
        )
      else
        for (final t in matchingTrips)
          ZPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ZLabel(
                      '${t.route} / ${routes.firstWhere((r) => r.id == t.route).name}',
                      color: ZColors.accent,
                    ),
                    ZStatus(t.status),
                  ],
                ),
                gap(22),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 15,
                  runSpacing: 8,
                  children: [
                    Text(t.time, style: ZTheme.display(46)),
                    const Icon(
                      Icons.arrow_forward,
                      size: 22,
                      color: ZColors.muted,
                    ),
                    Text(t.arrival, style: ZTheme.display(46)),
                  ],
                ),
                gap(17),
                const ZRule(),
                gap(18),
                Wrap(
                  spacing: 26,
                  runSpacing: 10,
                  children: [
                    ZLabel('ARRIVES ${t.arrival}'),
                    ZLabel(
                      '${widget.availableSeats(t)} / ${t.capacity} SEATS FREE',
                    ),
                    ZLabel('${t.plate} / ${t.driver}'),
                  ],
                ),
                gap(23),
                ZButton(
                  'Reserve this trip',
                  onPressed: () => widget.selectTrip(t, origin, destination),
                  icon: Icons.arrow_forward,
                ),
              ],
            ),
          ),
    ],
  );

  Widget seatsPage() {
    final t = widget.selectedTrip;
    final route = routes.firstWhere((r) => r.id == t.route);
    final availableSeats = widget.availableSeats(t);
    final journey = route.journeyBetween(origin, destination);
    final valid =
        seatCount <= 4 && seatCount <= availableSeats && journey != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          '10',
          'PASSENGER / RESERVATION',
          'MAKE ROOM\nFOR THE RIDE.',
          'Confirm your boarding and destination stops, then reserve up to four seats. Availability is checked against the selected run.',
          action: ZButton(
            'Back to results',
            secondary: true,
            onPressed: () => widget.go(ZPage.search),
            icon: Icons.arrow_back,
          ),
        ),
        columns([
          ZPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ZLabel('SELECTED DEPARTURE / ${t.id}', color: ZColors.accent),
                gap(22),
                Text('${t.time} — ${t.arrival}', style: ZTheme.display(43)),
                gap(18),
                Text(
                  route.name.toUpperCase(),
                  style: ZTheme.mono(12, color: ZColors.ink),
                ),
                gap(24),
                const ZRule(),
                gap(18),
                rowLabel('VEHICLE', t.plate),
                gap(13),
                rowLabel('CAPACITY', '${t.capacity} seats'),
                gap(13),
                rowLabel('AVAILABLE', '$availableSeats seats'),
              ],
            ),
          ),
          ZPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ZLabel('01 / JOURNEY DETAILS', color: ZColors.accent),
                gap(22),
                ZSelect(
                  'Board at',
                  value: origin,
                  items: route.stops.toSet().toList(),
                  onChanged: (v) => setState(() => origin = v ?? origin),
                ),
                gap(19),
                ZSelect(
                  'Get off at',
                  value: destination,
                  items: route.stops.toSet().toList(),
                  onChanged: (v) =>
                      setState(() => destination = v ?? destination),
                ),
              ],
            ),
          ),
        ], desktopColumns: 2),
        gap(24),
        ZPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZLabel('02 / SEATS', color: ZColors.accent),
              gap(18),
              Row(
                children: [
                  IconButton(
                    onPressed: seatCount > 1
                        ? () => setState(() => seatCount--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Container(
                    width: 68,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: ZColors.line),
                    ),
                    child: Text('$seatCount', style: ZTheme.display(34)),
                  ),
                  IconButton(
                    onPressed: seatCount < 4
                        ? () => setState(() => seatCount++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Maximum four seats per reservation.',
                      style: TextStyle(color: ZColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        gap(20),
        if (seatCount > availableSeats)
          ZNotice(
            'Insufficient seats',
            'Only $availableSeats seats remain on this run. Reduce your selection.',
            color: ZColors.accent,
            icon: Icons.error_outline,
          )
        else
          const ZNotice(
            'Booking window',
            'This demo uses a preview time of 08:40. Real reservations must close at least 20 minutes before arrival at the boarding stop.',
            color: ZColors.success,
          ),
        gap(22),
        ZButton(
          'Confirm $seatCount ${seatCount == 1 ? 'seat' : 'seats'}',
          onPressed: valid
              ? () => widget.book(seatCount, origin, destination)
              : null,
          icon: Icons.arrow_forward,
        ),
      ],
    );
  }

  Widget confirmationPage() {
    final reservation = widget.selectedReservation;
    if (reservation == null) {
      return ZEmpty(
        'No boarding pass yet',
        'Reserve a trip to generate your pass.',
        action: ZButton(
          'Find a trip',
          onPressed: () => widget.go(ZPage.search),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          '11',
          'PASSENGER / YOUR PASS',
          reservation.status == ReservationStatus.cancelled
              ? 'THIS RIDE\nWAS CANCELLED.'
              : 'YOU ARE\nON BOARD.',
          'Your reservation details and check-in token for the driver. Keep this pass ready when the bus reaches your stop.',
          action: ZButton(
            'My reservations',
            secondary: true,
            onPressed: () => widget.go(ZPage.reservations),
            icon: Icons.arrow_forward,
          ),
        ),
        columns([
          ZPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ZLabel(
                      'BOARDING PASS / ${reservation.id}',
                      color: ZColors.accent,
                    ),
                    ZStatus(reservation.status.label),
                  ],
                ),
                gap(32),
                Text(reservation.time, style: ZTheme.display(66)),
                gap(8),
                Text(
                  'MONDAY / 14 SEPTEMBER 2026',
                  style: ZTheme.mono(11, color: ZColors.ink),
                ),
                gap(28),
                const ZRule(),
                gap(21),
                rowLabel('FROM', reservation.from),
                gap(17),
                rowLabel('TO', reservation.to),
                gap(17),
                rowLabel('ROUTE', reservation.route),
                gap(17),
                rowLabel('SEATS', reservation.seats.toString()),
                gap(30),
                const ZNotice(
                  'Check-in',
                  'Show your QR token to the driver at your boarding stop. A pass is valid only for its assigned run.',
                  color: ZColors.success,
                ),
              ],
            ),
          ),
          ZPanel(
            child: Column(
              children: [
                const ZLabel('SCAN AT BOARDING'),
                gap(26),
                Container(
                  color: ZColors.ink,
                  padding: const EdgeInsets.all(18),
                  child: CustomPaint(
                    size: const Size(222, 222),
                    painter: _QrPreviewPainter(reservation.token),
                  ),
                ),
                gap(23),
                Text(
                  reservation.token,
                  textAlign: TextAlign.center,
                  style: ZTheme.mono(11, color: ZColors.ink),
                ),
                gap(11),
                const Text(
                  'Visual QR mockup / use token for prototype check-in',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ZColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ], desktopColumns: 2),
      ],
    );
  }

  Widget reservationsPage() {
    final filtered = widget.reservations
        .where(
          (r) => switch (reservationFilter) {
            'Upcoming' => r.status == ReservationStatus.confirmed,
            'Completed' =>
              r.status == ReservationStatus.completed ||
                  r.status == ReservationStatus.checkedIn,
            'Cancelled' => r.status == ReservationStatus.cancelled,
            _ => true,
          },
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          '12',
          'PASSENGER / HISTORY',
          'YOUR RIDES,\nALL IN ONE PLACE.',
          'View upcoming, completed and cancelled rides. Cancelling a confirmed reservation releases its seats back to the run.',
          action: ZButton(
            'Book another ride',
            onPressed: () => widget.go(ZPage.search),
            icon: Icons.arrow_forward,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Upcoming', 'Completed', 'Cancelled', 'All']
              .map(
                (f) => ZButton(
                  f,
                  secondary: reservationFilter != f,
                  compact: true,
                  onPressed: () => setState(() => reservationFilter = f),
                ),
              )
              .toList(),
        ),
        gap(25),
        if (filtered.isEmpty)
          ZEmpty(
            'Nothing here yet',
            'No reservations match this filter.',
            action: ZButton(
              'Find a trip',
              onPressed: () => widget.go(ZPage.search),
            ),
          )
        else
          for (final r in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ZPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: ZLabel(r.id, color: ZColors.accent)),
                        ZStatus(r.status.label),
                      ],
                    ),
                    gap(20),
                    Text('${r.time}  /  ${r.route}', style: ZTheme.display(35)),
                    gap(17),
                    Text(
                      '${r.from}  →  ${r.to}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    gap(16),
                    ZLabel(
                      '${r.seats} ${r.seats == 1 ? 'SEAT' : 'SEATS'} / MON 14 SEP',
                    ),
                    gap(20),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        ZButton(
                          'View pass',
                          secondary: true,
                          compact: true,
                          onPressed: () => widget.selectReservation(r),
                          icon: Icons.arrow_forward,
                        ),
                        if (r.status == ReservationStatus.confirmed)
                          ZButton(
                            'Cancel',
                            secondary: true,
                            compact: true,
                            onPressed: () => confirm(
                              'Cancel reservation?',
                              'The ${r.seats} reserved ${r.seats == 1 ? 'seat' : 'seats'} will return to available capacity.',
                              () {
                                widget.cancel(r);
                                message(
                                  'Reservation cancelled; seats released.',
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget driverDayPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '13',
        'DRIVER / MON 14 SEP',
        'YOUR DAY\nON THE ROAD.',
        'A clear view of every assigned run, vehicle and departure. Open a trip to see boarding activity at each stop.',
        action: const ZStatus('4 ASSIGNMENTS'),
      ),
      ZPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZLabel('NEXT UP / RUN 01', color: ZColors.accent),
            gap(25),
            Text('09:30', style: ZTheme.display(68)),
            gap(11),
            Text(
              'UNIVERSITY LOOP / R01',
              style: ZTheme.mono(12, color: ZColors.ink),
            ),
            gap(24),
            const ZRule(),
            gap(17),
            rowLabel('VEHICLE', 'SY 2591 / 9-SEAT VAN'),
            gap(13),
            rowLabel('FIRST STOP', stops[0]),
            gap(13),
            rowLabel('BOOKED', '6 PASSENGERS / 3 SEATS FREE'),
            gap(23),
            ZButton(
              widget.tripStarted ? 'Continue trip' : 'Start trip',
              onPressed: widget.tripStarted
                  ? () => widget.go(ZPage.driverTrip)
                  : widget.onStart,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
      gap(42),
      ZSectionTitle('01 / FULL ROSTER', 'Assigned runs'),
      for (final t in trips.where((t) => t.driver == 'John Driver'))
        ZRecord(
          title:
              '${t.time} / ${routes.firstWhere((r) => r.id == t.route).name}',
          subtitle: t.id,
          fields: {
            'Window': '${t.time}–${t.arrival}',
            'Vehicle': t.plate,
            'Booked': '${t.capacity - t.available} / ${t.capacity}',
          },
          status: t.time == '09:30' && widget.tripStarted
              ? 'In progress'
              : t.status,
          onTap: () => widget.go(ZPage.driverTrip),
        ),
    ],
  );

  Widget driverTripPage() {
    final t = trips[0], route = routes[0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          '14',
          'DRIVER / RUN DETAIL',
          'EVERY STOP\nCOUNTS.',
          'Boarding and alighting detail for the active University loop. Confirm each passenger at the correct stop and on the correct run.',
          action: ZButton(
            'Open check-in',
            onPressed: () => widget.go(ZPage.checkIn),
            icon: Icons.qr_code_scanner,
          ),
        ),
        columns([
          ZStat(
            'Booked seats',
            '${t.capacity - t.available}',
            'Across the full route',
          ),
          ZStat(
            'Checked in',
            widget.scanned ? '05' : '04',
            'Passengers verified',
          ),
          ZStat('Remaining', widget.scanned ? '01' : '02', 'Not yet boarded'),
        ]),
        gap(38),
        ZSectionTitle('01 / STOP SEQUENCE', 'Boarding plan'),
        for (final stop in route.stops.asMap().entries)
          ZRecord(
            title: stop.value,
            subtitle:
                'STOP ${(stop.key + 1).toString().padLeft(2, '0')} / ${stop.key == 0 ? '09:30' : '+${stop.key * 5} MIN'}',
            fields: {
              'Board': stop.key == 0
                  ? '3 passengers'
                  : stop.key == 1
                  ? '2 passengers'
                  : '0 passengers',
              'Alight': stop.key == 2
                  ? '2 passengers'
                  : stop.key == 3
                  ? '1 passenger'
                  : '0 passengers',
            },
            status: stop.key == 0 ? 'Current stop' : 'Upcoming',
            onTap: () => setState(() => activeStop = stop.value),
          ),
        gap(34),
        ZSectionTitle('02 / MANIFEST', 'Expected passengers'),
        ZTable(
          headers: const ['Passenger', 'Board', 'Alight', 'Seats', 'Status'],
          rows: [
            ZRecord(
              title: 'John Passenger',
              subtitle: 'BKG-240914-018',
              fields: {'Board': stops[0], 'Alight': stops[2], 'Seats': '2'},
              status: widget.scanned ? 'Checked in' : 'Confirmed',
            ),
            ZRecord(
              title: 'Jane Passenger',
              subtitle: 'BKG-240914-021',
              fields: {'Board': stops[1], 'Alight': stops[3], 'Seats': '1'},
              status: 'Confirmed',
            ),
            ZRecord(
              title: 'James Passenger',
              subtitle: 'BKG-240914-022',
              fields: {'Board': stops[0], 'Alight': stops[2], 'Seats': '1'},
              status: 'Checked in',
            ),
          ],
        ),
        gap(35),
        ZButton(
          'Close trip & summarize',
          onPressed: () => confirm(
            'Complete this run?',
            'Close the trip and review checked-in passengers and no-shows.',
            widget.onClose,
          ),
          icon: Icons.arrow_forward,
        ),
      ],
    );
  }

  Widget checkInPage() {
    final input = scanController.text.trim().toUpperCase();
    final result = CheckInValidator.validate(
      token: input,
      activeTripId: trips.first.id,
      activeStop: activeStop,
      reservations: widget.reservations,
      scannedTokens: widget.scanned ? const {'QR-BKG-240914-018'} : const {},
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          '15',
          'DRIVER / BOARDING CONTROL',
          'SCAN. VERIFY.\nLET THEM RIDE.',
          'Check each pass against the assigned run and boarding stop. A pass for another run must be rejected.',
          action: ZButton(
            'Back to trip',
            secondary: true,
            onPressed: () => widget.go(ZPage.driverTrip),
            icon: Icons.arrow_back,
          ),
        ),
        columns([
          ZPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ZLabel('CURRENT BOARDING POINT', color: ZColors.accent),
                gap(18),
                Text('MUT CAMPUS', style: ZTheme.display(38)),
                gap(19),
                ZSelect(
                  'Stop',
                  value: activeStop,
                  items: routes[0].stops.toSet().toList(),
                  onChanged: (v) =>
                      setState(() => activeStop = v ?? activeStop),
                ),
                gap(20),
                rowLabel('RUN', 'R01 / 09:30'),
                gap(11),
                rowLabel('VEHICLE', 'SY 2591'),
              ],
            ),
          ),
          ZPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ZLabel('SCAN ZONE / PREVIEW', color: ZColors.accent),
                gap(19),
                Container(
                  width: double.infinity,
                  height: 185,
                  decoration: BoxDecoration(
                    border: Border.all(color: ZColors.line),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 82,
                      color: ZColors.muted,
                    ),
                  ),
                ),
                gap(16),
                const Text(
                  'Camera preview is represented visually. Enter a demo token below to verify a pass.',
                  style: TextStyle(
                    fontSize: 12,
                    color: ZColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ], desktopColumns: 2),
        gap(24),
        ZField(
          'Reservation QR token',
          controller: scanController,
          hint: 'QR-BKG-240914-018',
          onChanged: (_) => setState(() {}),
        ),
        gap(13),
        const ZLabel('TRY: QR-BKG-240914-018 / QR-BKG-220914-007'),
        gap(20),
        ZButton(
          'Verify token',
          onPressed: input.isEmpty
              ? null
              : () => setState(() => showError = true),
          icon: Icons.arrow_forward,
        ),
        if (showError) ...[
          gap(23),
          if (result == CheckInResult.accepted ||
              result == CheckInResult.alreadyCheckedIn)
            ZNotice(
              result == CheckInResult.alreadyCheckedIn
                  ? 'Already checked in'
                  : 'Pass accepted',
              'John User / 2 seats / R01 09:30 / boarding at MUT campus.',
              color: ZColors.success,
              icon: Icons.check_circle_outline,
            )
          else if (result == CheckInResult.wrongRun)
            const ZNotice(
              'Wrong run',
              'This pass belongs to another run and cannot be used for R01 at 09:30.',
              color: ZColors.accent,
              icon: Icons.error_outline,
            )
          else if (result == CheckInResult.wrongStop)
            const ZNotice(
              'Wrong stop',
              'This reservation boards at MUT campus. Select the correct stop before check-in.',
              color: ZColors.accent,
              icon: Icons.error_outline,
            )
          else
            const ZNotice(
              'Pass not found',
              'No matching reservation token exists in this mockup.',
              color: ZColors.accent,
              icon: Icons.error_outline,
            ),
          if (result == CheckInResult.accepted) ...[
            gap(16),
            ZButton(
              'Confirm boarding',
              onPressed: widget.onScan,
              icon: Icons.check,
            ),
          ],
        ],
      ],
    );
  }

  Widget completionPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '16',
        'DRIVER / CLOSEOUT',
        'RUN COMPLETE.\nPEOPLE ACCOUNTED FOR.',
        'A final record of passengers who boarded, seats used and reservations that did not turn into rides.',
        action: const ZStatus('CLOSED / 10:02'),
      ),
      columns([
        const ZStat('Booked passengers', '06', 'Across the route'),
        ZStat(
          'Checked in',
          widget.scanned ? '05' : '04',
          'Boarded successfully',
        ),
        ZStat('No-shows', widget.scanned ? '01' : '02', 'Reserved but absent'),
      ]),
      gap(39),
      ZSectionTitle('01 / CLOSEOUT', 'Run R01 / 09:30'),
      ZPanel(
        child: Column(
          children: [
            rowLabel('ROUTE', 'UNIVERSITY LOOP'),
            gap(18),
            const ZRule(),
            gap(18),
            rowLabel('DRIVER', 'John Driver'),
            gap(18),
            const ZRule(),
            gap(18),
            rowLabel('VEHICLE', 'SY 2591 / 9-SEAT VAN'),
            gap(18),
            const ZRule(),
            gap(18),
            rowLabel('ACTUAL WINDOW', '09:30 — 10:02'),
          ],
        ),
      ),
      gap(34),
      ZSectionTitle('02 / EXCEPTIONS', 'Passengers not boarded'),
      ZRecord(
        title: 'John Pasenger',
        subtitle: 'BKG-240914-021',
        fields: {'Board': stops[1], 'Seats': '1', 'Reason': 'No scan recorded'},
        status: 'No-show',
      ),
      gap(35),
      ZButton(
        'Back to my day',
        onPressed: () => widget.go(ZPage.driverDay),
        icon: Icons.arrow_forward,
      ),
    ],
  );

  Widget reportsPage() {
    final reportNames = [
      'Boardings / alightings',
      'Reservation outcomes',
      'Passenger behavior',
      'Route usage by weekday',
      'Stop usage by run',
      'Driver assignments',
      'Vehicle type utilization',
    ];
    final data = switch (report) {
      'Boardings / alightings' => [120, 95, 70, 86, 75, 91, 106],
      'Reservation outcomes' => [86, 74, 12, 8, 5, 3, 0],
      'Passenger behavior' => [12, 10, 8, 6, 5, 0, 0],
      'Route usage by weekday' => [285, 275, 310, 295, 340, 190, 170],
      'Stop usage by run' => [120, 95, 70, 110, 85, 60, 0],
      'Driver assignments' => [25, 20, 18, 15, 12, 10, 0],
      _ => [63, 37, 20, 0, 0, 0, 0],
    };
    final labels = switch (report) {
      'Route usage by weekday' => [
        'MON',
        'TUE',
        'WED',
        'THU',
        'FRI',
        'SAT',
        'SUN',
      ],
      'Driver assignments' => ['SOM', 'SOMM', 'SOMK', 'ARE', 'WAR', 'NAN', ''],
      'Vehicle type utilization' => ['VAN', 'BUS', 'MINI', '', '', '', ''],
      'Reservation outcomes' => [
        'BOOK',
        'SEAT',
        'CXL',
        'SCAN',
        'NO-SHOW',
        '',
        '',
      ],
      _ => ['MUT', 'LOTUS', 'HOSP', 'BIG C', 'PARK', 'MAKRO', 'OTHER'],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          '17',
          'ANALYTICS / SERVICE INTELLIGENCE',
          'READ THE\nMOVEMENT.',
          'Explore demand, booking outcomes, passenger behavior and utilization with data views drawn from the ZBus reporting requirements.',
          action: ZButton(
            'Export view',
            secondary: true,
            onPressed: () =>
                message('Report export is a visual mockup action.'),
            icon: Icons.arrow_forward,
          ),
        ),
        columns([
          ZSelect(
            'Report view',
            value: report,
            items: reportNames,
            onChanged: (v) => setState(() => report = v ?? report),
          ),
          const ZSelect(
            'Year',
            value: '2026',
            items: ['2026', '2025'],
            onChanged: null,
          ),
          const ZSelect(
            'Period',
            value: 'September',
            items: ['September', 'August', 'April'],
            onChanged: null,
          ),
        ]),
        gap(32),
        columns([
          ZStat(
            'Total activity',
            data.fold<int>(0, (a, b) => a + b).toString(),
            report,
          ),
          const ZStat('Routes covered', '03', 'University / Park / Crossline'),
          const ZStat('Stops covered', '07', 'MUT and Nong Chok area'),
        ]),
        gap(43),
        ZSectionTitle('01 / TREND', report),
        ZPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZLabel(
                'SERVICE MEASURE / SELECTED PERIOD',
                color: ZColors.accent,
              ),
              gap(31),
              SizedBox(
                height: 240,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < data.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${data[i]}',
                                style: ZTheme.mono(9, color: ZColors.ink),
                              ),
                              const SizedBox(height: 8),
                              AnimatedContainer(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 250),
                                height: data[i] == 0
                                    ? 2
                                    : 155 * data[i] / data.reduce(math.max),
                                color: i == 0 ? ZColors.accent : ZColors.ink,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ZTheme.mono(8),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        gap(38),
        ZSectionTitle('02 / DETAIL', 'Source breakdown'),
        ZTable(
          headers: const ['Category', 'Measure', 'Share', 'Period'],
          rows: [
            for (var i = 0; i < data.length; i++)
              if (labels[i].isNotEmpty)
                ZRecord(
                  title: labels[i],
                  subtitle: 'REPORT / ${(i + 1).toString().padLeft(2, '0')}',
                  fields: {
                    'Measure': data[i].toString(),
                    'Share':
                        '${(data[i] / data.fold<int>(0, (a, b) => a + b) * 100).toStringAsFixed(1)}%',
                    'Period': 'SEP 2026',
                  },
                ),
          ],
        ),
        gap(26),
        const ZNotice(
          'Mock data',
          'Values illustrate the reporting views described in the project reference. Connect the final reports to booking, check-in and trip-log records.',
          color: ZColors.success,
        ),
      ],
    );
  }

  Widget profilePage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '18',
        'MEMBER / ACCOUNT',
        'YOUR PLACE\nIN THE NETWORK.',
        'Keep your identity and contact details current. Position determines which parts of the system appear in your navigation.',
      ),
      columns([
        ZPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZLabel('MEMBER CARD / MUT', color: ZColors.accent),
              gap(27),
              CircleAvatar(
                radius: 40,
                backgroundColor: ZColors.surface2,
                child: Text('NM', style: ZTheme.display(28)),
              ),
              gap(25),
              Text(profileName.text.toUpperCase(), style: ZTheme.display(35)),
              gap(10),
              Text(
                profileEmail.text,
                style: const TextStyle(color: ZColors.muted),
              ),
              gap(28),
              const ZRule(),
              gap(20),
              rowLabel('MEMBER ID', 'MUT-260914-014'),
              gap(13),
              rowLabel('POSITION', switch (widget.role) {
                ZRole.admin => 'OPERATIONS MANAGER',
                ZRole.passenger => 'STUDENT',
                ZRole.driver => 'DRIVER',
              }),
            ],
          ),
        ),
        ZPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZLabel('PROFILE DETAILS', color: ZColors.accent),
              gap(24),
              ZField(
                'Display name',
                controller: profileName,
                onChanged: (_) => setState(() {}),
              ),
              gap(20),
              ZField(
                'Institutional email',
                controller: profileEmail,
                onChanged: (_) => setState(() {}),
              ),
              gap(24),
              ZButton(
                'Save profile',
                onPressed: () =>
                    message('Profile details saved in this prototype.'),
                icon: Icons.arrow_forward,
              ),
            ],
          ),
        ),
      ], desktopColumns: 2),
      gap(28),
      const ZNotice(
        'Security',
        'Authentication and account changes are visual prototype flows. Production access requires server-side validation.',
        color: ZColors.success,
      ),
    ],
  );

  Widget statesPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '19',
        'SYSTEM / STATE LIBRARY',
        'EVERY SIGNAL\nHAS A STATE.',
        'Consistent feedback for moments when a request is waiting, succeeds, needs attention or cannot continue.',
      ),
      columns([
        const ZEmpty(
          'Nothing scheduled',
          'New departures will appear here when a route and vehicle are assigned.',
        ),
        ZPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZLabel('LOADING'),
              gap(26),
              const LinearProgressIndicator(
                color: ZColors.ink,
                backgroundColor: ZColors.line,
              ),
              gap(21),
              Text('CHECKING THE NETWORK', style: ZTheme.display(27)),
              gap(11),
              const Text(
                'Please wait while available trips are refreshed.',
                style: TextStyle(color: ZColors.muted),
              ),
            ],
          ),
        ),
        const ZNotice(
          'Reservation confirmed',
          'Your pass is ready. Show its QR token when you board.',
          color: ZColors.success,
          icon: Icons.check_circle_outline,
        ),
        const ZNotice(
          'Only two seats left',
          'Select two seats or choose a later departure.',
          color: ZColors.warning,
        ),
        const ZNotice(
          'Assignment conflict',
          'This driver already has an overlapping departure. Choose another driver or time.',
          color: ZColors.accent,
          icon: Icons.error_outline,
        ),
      ], desktopColumns: 2),
      gap(42),
      ZSectionTitle('01 / CONTROLS', 'Interaction examples'),
      columns([
        const ZField('Search', hint: 'Search routes, people or IDs'),
        const ZSelect(
          'Route',
          value: 'R01',
          items: ['R01', 'R02', 'R03'],
          onChanged: null,
        ),
      ], desktopColumns: 2),
      gap(25),
      Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          ZButton(
            'Success notice',
            onPressed: () => message('Operation completed successfully.'),
          ),
          ZButton(
            'Open dialog',
            secondary: true,
            onPressed: () => confirm(
              'Review action?',
              'This dialog demonstrates the consistent confirmation pattern.',
              () => message('Action confirmed.'),
            ),
          ),
          ZButton(
            'Loading preview',
            secondary: true,
            onPressed: () async {
              setState(() => loading = true);
              await Future<void>.delayed(const Duration(milliseconds: 900));
              if (mounted) setState(() => loading = false);
            },
          ),
        ],
      ),
      if (loading) ...[
        gap(22),
        const LinearProgressIndicator(
          color: ZColors.ink,
          backgroundColor: ZColors.line,
        ),
      ],
    ],
  );
}

class _QrPreviewPainter extends CustomPainter {
  _QrPreviewPainter(this.token);
  final String token;
  @override
  void paint(Canvas canvas, Size size) {
    const n = 29;
    final cell = size.width / n;
    final paint = Paint()..color = ZColors.bg;
    final seed = token.codeUnits.fold<int>(1, (a, b) => a * 31 + b);
    bool finder(int x, int y, int ox, int oy) {
      final dx = x - ox, dy = y - oy;
      if (dx < 0 || dy < 0 || dx > 6 || dy > 6) return false;
      return dx == 0 ||
          dy == 0 ||
          dx == 6 ||
          dy == 6 ||
          (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4);
    }

    bool finderZone(int x, int y, int ox, int oy) =>
        x >= ox - 1 && x <= ox + 7 && y >= oy - 1 && y <= oy + 7;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final inFinder =
            finderZone(x, y, 0, 0) ||
            finderZone(x, y, n - 7, 0) ||
            finderZone(x, y, 0, n - 7);
        final dark =
            finder(x, y, 0, 0) ||
            finder(x, y, n - 7, 0) ||
            finder(x, y, 0, n - 7) ||
            (!inFinder && ((x * 17 + y * 29 + seed + x * y * 7) % 11 < 5));
        if (dark) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell + .15, cell + .15),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPreviewPainter oldDelegate) =>
      token != oldDelegate.token;
}
