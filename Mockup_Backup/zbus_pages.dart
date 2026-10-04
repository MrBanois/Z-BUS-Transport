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
    this.sessionUser,
    this.onBoard,
    required this.page,
    required this.role,
    required this.selectedTrip,
    required this.initialOrigin,
    required this.initialDestination,
    required this.selectedReservation,
    required this.reservations,
    required this.bookingDraft,
    required this.tripStarted,
    required this.scanned,
    required this.availableSeats,
    required this.go,
    required this.selectTrip,
    required this.book,
    required this.cancel,
    required this.cancelBooking,
    required this.checkout,
    required this.selectReservation,
    required this.onStart,
    required this.onClose,
    required this.onScan,
  });
  final SessionUser? sessionUser;
  final void Function(ReservationRecord, int)? onBoard;
  final ZPage page;
  final ZRole role;
  final TripRecord selectedTrip;
  final String initialOrigin, initialDestination;
  final ReservationRecord? selectedReservation;
  final List<ReservationRecord> reservations;
  final List<BookingDraftTrip> bookingDraft;
  final bool tripStarted, scanned;
  final int Function(TripRecord) availableSeats;
  final ValueChanged<ZPage> go;
  final void Function(TripRecord, String, String) selectTrip;
  final void Function(int, String, String) book;
  final ValueChanged<ReservationRecord> cancel, selectReservation;
  final ValueChanged<String> cancelBooking;
  final VoidCallback checkout;
  final VoidCallback onStart, onClose, onScan;
  @override
  State<ZPages> createState() => _ZPagesState();
}

class _ZPagesState extends State<ZPages> {
  final managedRoutes = List<RouteRecord>.of(routes);
  final stationRecords = <Map<String, String>>[
    for (var i = 0; i < stops.length; i++)
      {
        'ID': 'S${(i + 1).toString().padLeft(4, '0')}',
        'Name': stops[i],
        'IS_ACTIVE': 'T',
      },
  ];
  List<String> get managedStations =>
      stationRecords.map((s) => s['Name']!).toList();
  final managedSchedules = List<TripRecord>.of(trips);
  final manifestStatus = <String, String>{
    'John Passenger': 'Confirmed',
    'Jane Passenger': 'Confirmed',
    'James Passenger': 'Checked in',
  };
  late String origin = widget.initialOrigin;
  late String destination = widget.initialDestination;
  String reservationFilter = 'On wait';
  String report = 'Trip log', activeStop = stops[0];
  int seatCount = 1;
  bool searched = false, showError = false;
  final scanController = TextEditingController();
  final passengerCountController = TextEditingController();
  final boardingCounts = <String, int>{};
  String? boardingError;
  final profileName = TextEditingController(text: 'John');
  final profileLastName = TextEditingController(text: 'User');
  final profileEmail = TextEditingController(text: 'johnuser@zbus.co.th');
  final permissions = <String, Set<String>>{
    'Operations manager': {
      'Manage routes',
      'Manage stations',
      'Manage schedules',
      'Manage vehicles',
      'Statistic reports',
    },
    'Dispatcher': {
      'Manage routes',
      'Manage stations',
      'Manage schedules',
      'Manage vehicles',
      'Statistic reports',
    },
    'Driver': {
      'My driving schedule',
      'Active trip',
      'Scan passenger QR',
      'Completed trip',
    },
    'Student': {'Find a trip', 'Reserve seats', 'My reservations'},
  };
  String permissionRole = 'Dispatcher';
  String accountDepartment = 'PD001 / Technology';
  String accountPosition = 'PP001 / Student';
  @override
  void initState() {
    super.initState();
    for (final name in positionIds.keys) {
      permissions.putIfAbsent(name, () => <String>{});
    }
    final user = widget.sessionUser;
    if (user != null &&
        !user.isEmployee &&
        !users.any((u) => u['Email'] == user.email)) {
      final parts = user.name.split(' ');
      users.add({
        'ID': 'U000000010',
        'First name': parts.first,
        'Last name': parts.skip(1).join(' '),
        'Email': user.email,
        'Department': user.departmentId,
        'Position': user.positionId,
        'ISEMP': 'F',
        'Salary': '',
      });
      profileName.text = parts.first;
      profileLastName.text = parts.skip(1).join(' ');
      profileEmail.text = user.email;
      accountDepartment =
          '${user.departmentId} / ${departments.where((d) => d['ID'] == user.departmentId).map((d) => d['Name']).firstOrNull ?? 'Department'}';
      accountPosition =
          '${user.positionId} / ${positionIds.entries.where((e) => e.value == user.positionId).map((e) => e.key).firstOrNull ?? user.position}';
    }
  }

  @override
  void dispose() {
    scanController.dispose();
    passengerCountController.dispose();
    profileName.dispose();
    profileLastName.dispose();
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
      Expanded(flex: 2, child: ZLabel(label)),
      const SizedBox(width: 12),
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
    ZPage.departments => departmentsPage(),
    ZPage.positions => permissionsPage(),
    ZPage.users => usersPage(),
    ZPage.employees => usersPage(employeesOnly: true),
    ZPage.routes => routesPage(),
    ZPage.stops => stopsPage(),
    ZPage.schedules => schedulesPage(),
    ZPage.vehicles => vehiclesPage(),
    ZPage.search => searchPage(),
    ZPage.seats => seatsPage(),
    ZPage.bookingCart => bookingCartPage(),
    ZPage.confirmation => confirmationPage(),
    ZPage.reservations => reservationsPage(),
    ZPage.driverDay => driverDayPage(),
    ZPage.driverTrip => driverTripPage(),
    ZPage.checkIn => checkInPage(),
    ZPage.completion => completionPage(),
    ZPage.reports => reportsPage(),
    ZPage.profile => profilePage(),
  };

  final departments = <Map<String, String>>[
    {'ID': 'ED001', 'Name': 'Transport'},
    {'ID': 'ED002', 'Name': 'Management'},
    {'ID': 'PD001', 'Name': 'Technology'},
    {'ID': 'PD002', 'Name': 'Computer Science'},
    {'ID': 'PD003', 'Name': 'Civil Engineering'},
    {'ID': 'PD004', 'Name': 'Multimedia'},
    {'ID': 'PD005', 'Name': 'Architecture'},
    {'ID': 'PD006', 'Name': 'Business'},
  ];
  final users = <Map<String, String>>[
    {
      'ID': 'U000000001',
      'First name': 'John',
      'Last name': 'Driver',
      'Email': 'driver@mut.edu',
      'Department': 'ED001',
      'Position': 'EP001',
      'ISEMP': 'T',
      'Salary': '25000',
    },
    {
      'ID': 'U000000009',
      'First name': 'Admin',
      'Last name': 'System',
      'Email': 'admin@mut.edu',
      'Department': 'ED002',
      'Position': 'EP003',
      'ISEMP': 'T',
      'Salary': '35000',
    },
    {
      'ID': 'U000000004',
      'First name': 'Technology',
      'Last name': 'Student',
      'Email': 'student@mut.edu',
      'Department': 'PD001',
      'Position': 'PP001',
      'ISEMP': 'F',
      'Salary': '',
    },
  ];
  final vehicleRecords = <Map<String, String>>[
    {
      'ID': 'V0001',
      'Plate': 'SY 2591',
      'Seats': '9',
      'Type': 'Van',
      'IS_ACTIVE': 'T',
    },
    {
      'ID': 'V0002',
      'Plate': 'SY 2599',
      'Seats': '9',
      'Type': 'Van',
      'IS_ACTIVE': 'T',
    },
    {
      'ID': 'V0003',
      'Plate': 'BK 1130',
      'Seats': '20',
      'Type': 'Bus',
      'IS_ACTIVE': 'T',
    },
    {
      'ID': 'V0004',
      'Plate': 'NN 5566',
      'Seats': '15',
      'Type': 'Minibus',
      'IS_ACTIVE': 'T',
    },
  ];
  final positionIds = <String, String>{
    'Operations manager': 'EP002',
    'Dispatcher': 'EP004',
    'Driver': 'EP001',
    'Student': 'PP001',
    'Admin': 'EP003',
    'Teaching Assistant': 'PP002',
    'Teacher': 'PP003',
    'Guest': 'PP004',
  };

  String generatedId(Iterable<String> ids, String prefix, int digits) {
    final numbers = ids
        .where((id) => id.startsWith(prefix))
        .map((id) => int.tryParse(id.substring(prefix.length)) ?? 0);
    final next = numbers.fold<int>(0, math.max) + 1;
    return '$prefix${next.toString().padLeft(digits, '0')}';
  }

  String departmentName(String id) =>
      departments
          .where((d) => d['ID'] == id)
          .map((d) => d['Name']!)
          .firstOrNull ??
      'Unknown department';
  String positionName(String id) =>
      positionIds.entries
          .where((p) => p.value == id)
          .map((p) => p.key)
          .firstOrNull ??
      'Unknown position';

  Future<void> directoryDialog({
    required String title,
    required List<Map<String, String>> records,
    required Map<String, String> defaults,
    Map<String, String>? existing,
    Map<String, List<String>> choices = const {},
    Map<String, Map<String, String>> choiceLabels = const {},
    String? accountIdSuffix,
    Set<String> locked = const {},
    String? Function(Map<String, String>)? validate,
    bool Function()? canDelete,
    void Function(Map<String, String>)? afterSave,
  }) async {
    final values = Map<String, String>.of(existing ?? defaults);
    final controllers = {
      for (final key in values.keys)
        key: TextEditingController(text: values[key]),
    };
    var employeeType = values['ID']!.startsWith('E');
    final originalId = existing?['ID'];
    String? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text('${existing == null ? 'ADD' : 'EDIT'} $title'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (accountIdSuffix != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Account type: ${employeeType ? 'Employee' : 'Passenger'}',
                          ),
                        ),
                        Switch(
                          value: employeeType,
                          onChanged: (value) => update(() {
                            if (existing != null &&
                                canDelete != null &&
                                !canDelete()) {
                              error = 'This record is assigned to users. Reassign those users before changing its type.';
                              return;
                            }
                            employeeType = value;
                            final prefix =
                                '${value ? 'E' : 'P'}$accountIdSuffix';
                            final id =
                                originalId != null &&
                                    originalId.startsWith(prefix)
                                ? originalId
                                : generatedId(
                                    records.map((r) => r['ID']!),
                                    prefix,
                                    3,
                                  );
                            values['ID'] = id;
                            controllers['ID']!.text = id;
                            error = null;
                          }),
                        ),
                      ],
                    ),
                  for (final key in values.keys)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: choices.containsKey(key)
                          ? ZSelect(
                              key,
                              value: values[key]!,
                              itemLabels: choiceLabels[key] ?? const {},
                              items: {
                                ...choices[key]!,
                                values[key]!,
                              }.where((v) => v.isNotEmpty).toList(),
                              onChanged: locked.contains(key)
                                  ? null
                                  : (v) => update(() => values[key] = v!),
                            )
                          : TextField(
                              controller: controllers[key],
                              readOnly: locked.contains(key) || key == 'ID',
                              decoration: InputDecoration(labelText: key),
                            ),
                    ),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: ZColors.accent)),
                ],
              ),
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () {
                  if (canDelete != null && !canDelete()) {
                    update(
                      () => error = 'This record is still referenced. Reassign those records first.',
                    );
                    return;
                  }
                  setState(() => records.remove(existing));
                  Navigator.pop(ctx);
                },
                child: const Text('DELETE'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                for (final key in values.keys) {
                  if (!choices.containsKey(key)) {
                    values[key] = controllers[key]!.text.trim();
                  }
                }
                final invalid = validate?.call(values);
                if (values['ID']!.isEmpty ||
                    records.any(
                      (r) => !identical(r, existing) && r['ID'] == values['ID'],
                    )) {
                  update(() => error = 'Enter a unique ID.');
                  return;
                }
                if (invalid != null) {
                  update(() => error = invalid);
                  return;
                }
                setState(() {
                  if (existing == null) {
                    records.add(Map.of(values));
                  } else {
                    existing.addAll(values);
                  }
                  afterSave?.call(values);
                });
                Navigator.pop(ctx);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
    // Dialog exit animation still uses its controllers until it completes.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Widget departmentsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '02',
        'MASTER FILE / DEPARTMENTS',
        'TEAMS BEHIND\nTHE JOURNEY.',
        'Passenger IDs begin PD; employee IDs begin ED.',
        action: ZButton('Add department', onPressed: () => departmentDialog()),
      ),
      ZTable(
        headers: const ['Department', 'ID'],
        rows: [
          for (final record in departments)
            ZRecord(
              title: record['Name']!,
              subtitle: '',
              fields: {'ID': record['ID']!},
              onTap: () => departmentDialog(record),
            ),
        ],
      ),
    ],
  );
  void departmentDialog([Map<String, String>? record]) => directoryDialog(
    title: 'DEPARTMENT',
    records: departments,
    defaults: {
      'ID': generatedId(departments.map((r) => r['ID']!), 'PD', 3),
      'Name': '',
    },
    accountIdSuffix: 'D',
    existing: record,
    validate: (v) =>
        !RegExp(r'^[EP]D[0-9]{3}$').hasMatch(v['ID']!) || v['Name']!.isEmpty
        ? 'Enter a department name.'
        : null,
    canDelete: () => !users.any((u) => u['Department'] == record?['ID']),
  );

  Widget usersPage({bool employeesOnly = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '04',
        employeesOnly ? 'MASTER FILE / EMPLOYEES' : 'MASTER FILE / USERS',
        employeesOnly
            ? 'PEOPLE BEHIND\nTHE SERVICE.'
            : 'ONE USER TABLE.\nEVERY PERSON.',
        employeesOnly ? 'Employee accounts have ISEMP = T and a salary.' : 'All passengers and employees, including department and position.',
        action: ZButton(
          employeesOnly ? 'Add employee' : 'Add user',
          onPressed: () => userDialog(employee: employeesOnly),
        ),
      ),
      ZTable(
        headers: [
          'User',
          'Department',
          'Position',
          'ISEMP',
          if (employeesOnly) 'Salary',
        ],
        rows: [
          for (final u in users.where(
            (u) => !employeesOnly || u['ISEMP'] == 'T',
          ))
            ZRecord(
              title: '${u['First name']} ${u['Last name']}',
              subtitle: u['ID']!,
              fields: {
                'Department': departmentName(u['Department']!),
                'Position': positionName(u['Position']!),
                'ISEMP': u['ISEMP']!,
                if (employeesOnly) 'Salary': u['Salary']!,
              },
              onTap: () => userDialog(employee: u['ISEMP'] == 'T', record: u),
            ),
        ],
      ),
    ],
  );
  void userDialog({required bool employee, Map<String, String>? record}) =>
      directoryDialog(
        title: employee ? 'EMPLOYEE' : 'USER',
        records: users,
        defaults: {
          'ID': generatedId(users.map((r) => r['ID']!), 'U', 9),
          'First name': '',
          'Last name': '',
          'Email': '',
          'Department': employee ? 'ED001' : 'PD001',
          'Position': employee ? 'EP001' : 'PP001',
          'ISEMP': employee ? 'T' : 'F',
          'Salary': employee ? '0' : '',
        },
        existing: record,
        locked: {'ISEMP', if (!employee) 'Salary'},
        choiceLabels: {
          'Department': {for (final d in departments) d['ID']!: d['Name']!},
          'Position': {for (final p in positionIds.entries) p.value: p.key},
        },
        choices: {
          'Department': departments
              .where((d) => d['ID']!.startsWith(employee ? 'ED' : 'PD'))
              .map((d) => d['ID']!)
              .toList(),
          'Position': positionIds.values
              .where((id) => id.startsWith(employee ? 'EP' : 'PP'))
              .toList(),
        },
        validate: (v) {
          if (v['First name']!.isEmpty ||
              v['Last name']!.isEmpty ||
              !v['Email']!.contains('@')) {
            return 'Enter a first name, last name and valid email.';
          }
          final salary = double.tryParse(v['Salary']!);
          if (employee && (salary == null || !salary.isFinite || salary < 0)) {
            return 'Enter a non-negative salary.';
          }
          return null;
        },
      );

  Future<void> positionDialog([String? name]) async {
    final record = name == null
        ? null
        : {'ID': positionIds[name]!, 'Name': name};
    final records = [
      for (final entry in positionIds.entries)
        if (entry.key != name) {'ID': entry.value, 'Name': entry.key},
      ?record,
    ];
    await directoryDialog(
      title: 'POSITION',
      records: records,
      defaults: {'ID': generatedId(positionIds.values, 'PP', 3), 'Name': ''},
      accountIdSuffix: 'P',
      existing: record,
      validate: (v) =>
          !RegExp(r'^[EP]P[0-9]{3}$').hasMatch(v['ID']!) ||
              v['Name']!.isEmpty ||
              (v['Name'] != name && positionIds.containsKey(v['Name']))
          ? 'Enter a unique position name.'
          : null,
      canDelete: () =>
          permissions.length > 1 &&
          !users.any((u) => u['Position'] == record?['ID']),
      afterSave: (v) {
        final granted = permissions.remove(name) ?? <String>{};
        positionIds.remove(name);
        positionIds[v['Name']!] = v['ID']!;
        permissions[v['Name']!] = granted;
        permissionRole = v['Name']!;
      },
    );
    if (record != null && !records.contains(record)) {
      setState(() {
        positionIds.remove(name);
        permissions.remove(name);
        permissionRole = permissions.keys.first;
      });
    }
  }

  Widget permissionsPage() {
    final modules = [
      'Manage departments',
      'Manage positions',
      'Manage users',
      'Manage employees',
      'Manage routes',
      'Manage stations',
      'Manage schedules',
      'Manage vehicles',
      'Statistic reports',
      'Find a trip',
      'Reserve seats',
      'My reservations',
      'My driving schedule',
      'Active trip',
      'Scan passenger QR',
      'Completed trip',
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
            onPressed: () => positionDialog(),
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
                        Text(
                          '${positionIds[p]} / ${p.toUpperCase()}',
                          style: ZTheme.display(27),
                        ),
                        gap(17),
                        Text(
                          '${positionIds[p]!.startsWith('PP') ? 'Passenger' : 'Employee'} / ${permissions[p]!.length} screens enabled',
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
          'Edit position',
          onPressed: () => positionDialog(permissionRole),
        ),
        gap(12),
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
          onPressed: () => _routeDialog(),
          icon: Icons.add,
        ),
      ),
      columns(
        managedRoutes
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
      for (final r in managedRoutes)
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
  String nextRouteId() {
    var number = 1;
    while (managedRoutes.any(
      (r) => r.id == 'R${number.toString().padLeft(2, '0')}',
    )) {
      number++;
    }
    return 'R${number.toString().padLeft(2, '0')}';
  }

  Future<void> _routeDialog([RouteRecord? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final selectedStations = List<String>.of(existing?.stops ?? const []);
    if (managedStations.isEmpty) {
      message('Add stations before creating a route.');
      name.dispose();
      return;
    }
    final durations = <TextEditingController>[
      for (var i = 0; i < selectedStations.length; i++)
        TextEditingController(
          text: i == 0 ? '' : '${existing!.segmentMinutes[i - 1]}',
        ),
    ];
    final allDurationControllers = List<TextEditingController>.of(durations);
    var stationToAdd = managedStations.first;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(
            existing == null ? 'CREATE ROUTE' : 'EDIT ROUTE',
            style: ZTheme.display(37),
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ZField('Route name', controller: name, hint: 'Route name'),
                  gap(20),
                  const ZLabel('ORDERED STATIONS', color: ZColors.accent),
                  gap(12),
                  if (selectedStations.isEmpty)
                    const ZEmpty(
                      'No stations yet',
                      'Add at least two stations in travel order.',
                    )
                  else
                    for (
                      var index = 0;
                      index < selectedStations.length;
                      index++
                    )
                      Column(
                        children: [
                          Row(
                            children: [
                              ZLabel((index + 1).toString().padLeft(2, '0')),
                              const SizedBox(width: 14),
                              Expanded(child: Text(selectedStations[index])),
                              IconButton(
                                tooltip: 'Move up',
                                onPressed: index == 0
                                    ? null
                                    : () => update(() {
                                        final station = selectedStations
                                            .removeAt(index);
                                        selectedStations.insert(
                                          index - 1,
                                          station,
                                        );
                                      }),
                                icon: const Icon(Icons.arrow_upward, size: 17),
                              ),
                              IconButton(
                                tooltip: 'Move down',
                                onPressed: index == selectedStations.length - 1
                                    ? null
                                    : () => update(() {
                                        final station = selectedStations
                                            .removeAt(index);
                                        selectedStations.insert(
                                          index + 1,
                                          station,
                                        );
                                      }),
                                icon: const Icon(
                                  Icons.arrow_downward,
                                  size: 17,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove station',
                                onPressed: () => update(() {
                                  selectedStations.removeAt(index);
                                  durations.removeAt(index);
                                }),
                                icon: const Icon(Icons.close, size: 17),
                              ),
                            ],
                          ),
                          if (index == 0)
                            const Text(
                              'Time from previous station: null (first station)',
                            )
                          else
                            ZField(
                              'Minutes from previous station',
                              controller: durations[index],
                              hint: 'e.g. 5',
                              onChanged: (_) => update(() {}),
                            ),
                          const ZRule(),
                        ],
                      ),
                  gap(18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: ZSelect(
                          'Add station',
                          value: stationToAdd,
                          items: managedStations,
                          onChanged: (value) => update(
                            () => stationToAdd = value ?? stationToAdd,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ZButton(
                        'Add',
                        compact: true,
                        onPressed: () => update(() {
                          selectedStations.add(stationToAdd);
                          final duration = TextEditingController(
                            text: selectedStations.length == 1 ? '' : '5',
                          );
                          durations.add(duration);
                          allDurationControllers.add(duration);
                        }),
                        icon: Icons.add,
                      ),
                    ],
                  ),
                  gap(12),
                  Text(
                    'Total duration: ${durations.skip(1).fold<int>(0, (sum, c) => sum + (int.tryParse(c.text) ?? 0))} min. Each value is travel time from the previous station.',
                    style: TextStyle(color: ZColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (existing != null)
              ZButton(
                'Delete',
                secondary: true,
                onPressed: () {
                  if (managedSchedules.any(
                    (schedule) => schedule.route == existing.id,
                  )) {
                    message('Delete or reassign this route’s schedules first.');
                    return;
                  }
                  setState(() => managedRoutes.remove(existing));
                  Navigator.pop(ctx);
                  message('${existing.name} deleted from the mock directory.');
                },
              ),
            ZButton(
              'Cancel',
              secondary: true,
              onPressed: () => Navigator.pop(ctx),
            ),
            ZButton(
              'Save route',
              onPressed: () {
                if (name.text.trim().isEmpty || selectedStations.length < 2) {
                  message('Enter a name and add at least two stations.');
                  return;
                }
                if (durations
                    .skip(1)
                    .any(
                      (c) =>
                          int.tryParse(c.text) == null || int.parse(c.text) < 0,
                    )) {
                  message(
                    'Enter a non-negative whole number of minutes for each segment.',
                  );
                  return;
                }
                setState(() {
                  final record = RouteRecord(
                    existing?.id ?? nextRouteId(),
                    name.text.trim(),
                    List.unmodifiable(selectedStations),
                    [
                      for (final duration in durations.skip(1))
                        int.parse(duration.text),
                    ],
                    existing?.runs ?? 0,
                  );
                  if (existing == null) {
                    managedRoutes.add(record);
                  } else {
                    managedRoutes[managedRoutes.indexOf(existing)] = record;
                  }
                });
                Navigator.pop(ctx);
                message('Route and station order saved.');
              },
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    for (final c in allDurationControllers) {
      c.dispose();
    }
  }

  Widget stopsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '05',
        'MASTER FILE / STATIONS',
        'PLACES TO\nGET THERE.',
        'Manage station ID, name and active flag.',
        action: ZButton('Add station', onPressed: () => stationDialog()),
      ),
      ZTable(
        headers: const ['NAME', 'ID', 'IS_ACTIVE'],
        rows: [
          for (final station in stationRecords)
            ZRecord(
              title: station['Name']!,
              subtitle: '',
              fields: {
                'ID': station['ID']!,
                'IS_ACTIVE': station['IS_ACTIVE']!,
              },
              onTap: () => stationDialog(station),
            ),
        ],
      ),
    ],
  );
  void stationDialog([Map<String, String>? record]) {
    final oldName = record?['Name'];
    directoryDialog(
      title: 'STATION',
      records: stationRecords,
      defaults: {
        'ID': generatedId(stationRecords.map((r) => r['ID']!), 'S', 4),
        'Name': '',
        'IS_ACTIVE': 'T',
      },
      existing: record,
      choices: const {
        'IS_ACTIVE': ['T', 'F'],
      },
      validate: (v) =>
          v['Name']!.isEmpty ||
              stationRecords.any(
                (r) => !identical(r, record) && r['Name'] == v['Name'],
              )
          ? 'Enter a unique station name.'
          : null,
      canDelete: () => !managedRoutes.any((r) => r.stops.contains(oldName)),
      afterSave: (v) {
        if (oldName == null) return;
        for (var i = 0; i < managedRoutes.length; i++) {
          final r = managedRoutes[i];
          managedRoutes[i] = RouteRecord(
            r.id,
            r.name,
            [for (final stop in r.stops) stop == oldName ? v['Name']! : stop],
            r.segmentMinutes,
            r.runs,
          );
        }
        if (origin == oldName) origin = v['Name']!;
        if (destination == oldName) destination = v['Name']!;
      },
    );
  }

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
      ZSectionTitle('01 / DAILY SCHEDULE', 'Schedules grouped by route'),
      for (final route in managedRoutes)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ZPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${route.id} / ${route.name.toUpperCase()}',
                        style: ZTheme.display(28),
                      ),
                    ),
                    ZButton(
                      'Add schedule',
                      compact: true,
                      onPressed: () => _scheduleDialog(initialRoute: route.id),
                      icon: Icons.add,
                    ),
                  ],
                ),
                gap(12),
                ZLabel(route.stops.join('  →  ')),
                gap(18),
                for (final schedule in managedSchedules.where(
                  (candidate) => candidate.route == route.id,
                ))
                  Column(
                    children: [
                      ZRecord(
                        title: schedule.time,
                        subtitle: schedule.id,
                        fields: {
                          'Driver': schedule.driver,
                          'Vehicle': schedule.plate,
                          'IS_ACTIVE': schedule.isActive ? 'T' : 'F',
                        },

                        onTap: () => _scheduleDialog(t: schedule),
                      ),
                      timetableDisclosure(
                        title: const Text('See station timetable'),
                        children: [scheduleStationTable(schedule)],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
    ],
  );
  Future<void> _scheduleDialog({TripRecord? t, String? initialRoute}) async {
    if (managedRoutes.isEmpty) {
      message('Create a route first.');
      return;
    }
    String route = t?.route ?? initialRoute ?? managedRoutes.first.id,
        driver = t?.driver ?? 'John Driver',
        vehicle = t?.plate ?? 'SY 2591';
    var isActive = t?.isActive ?? true;
    final time = TextEditingController(text: t?.time ?? '16:00');
    String stationClock(int stationIndex) {
      try {
        final selectedRoute = managedRoutes.firstWhere(
          (candidate) => candidate.id == route,
        );
        final minutes =
            BookingRules.parseClockMinutes(time.text) +
            selectedRoute.minutesToStop(stationIndex);
        return BookingRules.formatClockMinutes(minutes);
      } on FormatException {
        return '--:--';
      }
    }

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
                    items: managedRoutes.map((r) => r.id).toList(),
                    onChanged: (v) => update(() => route = v ?? route),
                  ),
                  gap(15),
                  ZField(
                    'Departure time',
                    controller: time,
                    hint: 'HH:MM',
                    onChanged: (_) => update(() {}),
                  ),
                  gap(15),
                  ZSelect(
                    'Driver',
                    value: driver,
                    items: {
                      driver,
                      ...managedSchedules.map((s) => s.driver),
                      ...users
                          .where(
                            (u) =>
                                u['ISEMP'] == 'T' && u['Position'] == 'EP001',
                          )
                          .map((u) => '${u['First name']} ${u['Last name']}'),
                    }.toList(),
                    onChanged: (v) => update(() => driver = v ?? driver),
                  ),
                  gap(15),
                  ZSelect(
                    'Vehicle',
                    value: vehicle,
                    items: {
                      vehicle,
                      ...vehicleRecords
                          .where((v) => v['IS_ACTIVE'] == 'T')
                          .map((v) => v['Plate']!),
                    }.toList(),
                    onChanged: (v) => update(() => vehicle = v ?? vehicle),
                  ),
                  gap(20),
                  ZSelect(
                    'IS_ACTIVE',
                    value: isActive ? 'T' : 'F',
                    items: const ['T', 'F'],
                    onChanged: (v) => update(() => isActive = v == 'T'),
                  ),
                  gap(16),
                  const ZLabel('STATION TIMETABLE', color: ZColors.accent),
                  gap(10),
                  for (final station
                      in managedRoutes
                          .firstWhere((candidate) => candidate.id == route)
                          .stops
                          .asMap()
                          .entries)
                    Column(
                      children: [
                        rowLabel(
                          '${station.key + 1}. ${station.value}',
                          stationClock(station.key),
                        ),
                        gap(8),
                      ],
                    ),
                  gap(12),
                  const ZNotice(
                    'Before publishing',
                    'Check the full interval for both driver and vehicle conflicts.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (t != null)
              ZButton(
                'Delete',
                secondary: true,
                onPressed: () {
                  setState(() => managedSchedules.remove(t));
                  Navigator.pop(ctx);
                  message('${t.id} deleted from the timetable.');
                },
              ),
            ZButton(
              'Cancel',
              secondary: true,
              onPressed: () => Navigator.pop(ctx),
            ),
            ZButton(
              'Check & save',
              onPressed: () {
                final sourceRoute = managedRoutes.firstWhere(
                  (candidate) => candidate.id == route,
                );
                int startMinutes;
                try {
                  startMinutes = BookingRules.parseClockMinutes(time.text);
                } on FormatException {
                  message('Enter a valid departure time in HH:MM format.');
                  return;
                }
                final endMinutes = startMinutes + sourceRoute.minutes;
                final hasConflict =
                    isActive &&
                    managedSchedules.any((candidate) {
                      if (!candidate.isActive ||
                          identical(candidate, t) ||
                          (candidate.driver != driver &&
                              candidate.plate != vehicle)) {
                        return false;
                      }
                      final candidateRoute = managedRoutes.firstWhere(
                        (record) => record.id == candidate.route,
                      );
                      final candidateStart = BookingRules.parseClockMinutes(
                        candidate.time,
                      );
                      final candidateEnd =
                          candidateStart + candidateRoute.minutes;
                      return startMinutes < candidateEnd &&
                          candidateStart < endMinutes;
                    });
                if (hasConflict) {
                  message(
                    'The selected driver or vehicle has an overlapping schedule.',
                  );
                  return;
                }
                final selectedVehicle = vehicleRecords
                    .where((v) => v['Plate'] == vehicle)
                    .firstOrNull;
                if (selectedVehicle == null ||
                    (isActive && selectedVehicle['IS_ACTIVE'] != 'T')) {
                  message('Select an available vehicle from Manage Vehicles.');
                  return;
                }
                final capacity = int.parse(selectedVehicle['Seats']!);
                final reserved = (t?.capacity ?? 0) - (t?.available ?? 0);
                if (capacity < reserved) {
                  message('The vehicle cannot hold the already booked seats.');
                  return;
                }
                final arrival = BookingRules.formatClockMinutes(endMinutes);
                final record = TripRecord(
                  t?.id ?? 'RUN-$route-${time.text.replaceAll(':', '')}',
                  route,
                  time.text,
                  arrival,
                  driver,
                  vehicle,
                  capacity,
                  capacity - reserved,
                  'Scheduled',
                  isActive: isActive,
                );
                setState(() {
                  if (t == null) {
                    managedSchedules.add(record);
                  } else {
                    managedSchedules[managedSchedules.indexOf(t)] = record;
                  }
                });
                Navigator.pop(ctx);
                message(
                  '${sourceRoute.name} departure saved after the mock conflict check.',
                );
              },
            ),
          ],
        ),
      ),
    );
    time.dispose();
  }

  Widget vehiclesPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '07',
        'FLEET / VEHICLES',
        'THE FLEET\nIN MOTION.',
        'Maintain vehicle registration, capacity, type and availability.',
        action: ZButton('Add vehicle', onPressed: () => vehicleDialog()),
      ),
      ZTable(
        headers: const ['Registration', 'Type', 'Capacity', 'IS_ACTIVE'],
        rows: [
          for (final v in vehicleRecords)
            ZRecord(
              title: v['Plate']!,
              subtitle: v['ID']!,
              fields: {
                'Type': v['Type']!,
                'Capacity': v['Seats']!,
                'IS_ACTIVE': v['IS_ACTIVE']!,
              },
              onTap: () => vehicleDialog(v),
            ),
        ],
      ),
    ],
  );
  void vehicleDialog([Map<String, String>? record]) => directoryDialog(
    title: 'VEHICLE',
    records: vehicleRecords,
    defaults: {
      'ID': generatedId(vehicleRecords.map((r) => r['ID']!), 'V', 4),
      'Plate': '',
      'Seats': '9',
      'Type': 'Van',
      'IS_ACTIVE': 'T',
    },
    existing: record,
    choices: const {
      'Type': ['Van', 'Bus', 'Minibus'],
      'IS_ACTIVE': ['T', 'F'],
    },
    validate: (v) =>
        v['Plate']!.isEmpty ||
            (int.tryParse(v['Seats']!) ?? 0) < 1 ||
            (int.tryParse(v['Seats']!) ?? 100) > 99
        ? 'Enter a plate and capacity between 1 and 99.'
        : null,
    canDelete: () => !managedSchedules.any((s) => s.plate == record?['Plate']),
  );

  List<TripRecord> get matchingTrips => BookingRules.eligibleTrips(
    origin: origin,
    destination: destination,
    currentMinutes: 8 * 60 + 40,
    trips: managedSchedules.where((t) => t.isActive).toList(),
    routes: managedRoutes,
  );

  Widget timetableDisclosure({
    required Widget title,
    required List<Widget> children,
  }) => Material(
    color: Colors.transparent,
    child: ExpansionTile(title: title, children: children),
  );

  String scheduleArrival(TripRecord trip) => BookingRules.formatClockMinutes(
    BookingRules.parseClockMinutes(trip.time) +
        managedRoutes.firstWhere((r) => r.id == trip.route).minutes,
  );

  Widget scheduleStationTable(TripRecord trip) {
    final route = managedRoutes.firstWhere(
      (candidate) => candidate.id == trip.route,
    );
    final start = BookingRules.parseClockMinutes(trip.time);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZLabel('ROUTE TIMETABLE', color: ZColors.accent),
        gap(10),
        for (final station in route.stops.asMap().entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: rowLabel(
              '${station.key + 1}. ${station.value}',
              BookingRules.formatClockMinutes(
                start + route.minutesToStop(station.key),
              ),
            ),
          ),
      ],
    );
  }

  Widget searchPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '09',
        'PASSENGER / PLAN A RIDE',
        'WHERE TO\nNEXT?',
        'Choose your boarding and destination stops. We show only runs with enough time to reserve before boarding.',
        action: widget.bookingDraft.isEmpty
            ? const ZStatus('NETWORK OPERATING')
            : ZButton(
                'Review ${widget.bookingDraft.length} ${widget.bookingDraft.length == 1 ? 'trip' : 'trips'}',
                onPressed: () => widget.go(ZPage.bookingCart),
                icon: Icons.shopping_bag_outlined,
              ),
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
                items: managedStations,
                onChanged: (v) => setState(() {
                  origin = v ?? origin;
                  searched = false;
                }),
              ),
              ZSelect(
                'Get off at',
                value: destination,
                items: managedStations,
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
                      '${t.route} / ${managedRoutes.firstWhere((r) => r.id == t.route).name}',
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
                gap(20),
                const ZRule(),
                gap(18),
                scheduleStationTable(t),
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
    final route = managedRoutes.firstWhere((r) => r.id == t.route);
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
          'Add trip · $seatCount ${seatCount == 1 ? 'seat' : 'seats'}',
          onPressed: valid
              ? () => widget.book(seatCount, origin, destination)
              : null,
          icon: Icons.arrow_forward,
        ),
      ],
    );
  }

  Widget bookingCartPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        '11',
        'PASSENGER / BOOKING REVIEW',
        'ONE BOOKING.\nEVERY TRIP.',
        'All selected trips will share one booking ID. Each trip keeps its own detail number, QR token, seats and cancellation status.',
        action: ZButton(
          'Add another trip',
          secondary: true,
          onPressed: () => widget.go(ZPage.search),
          icon: Icons.add,
        ),
      ),
      if (widget.bookingDraft.isEmpty)
        ZEmpty(
          'No trips selected',
          'Find a departure and add it to this booking.',
          action: ZButton(
            'Find a trip',
            onPressed: () => widget.go(ZPage.search),
          ),
        )
      else ...[
        for (var i = 0; i < widget.bookingDraft.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ZRecord(
              title:
                  '${widget.bookingDraft[i].trip.time} / ${widget.bookingDraft[i].trip.route}',
              subtitle: 'TRIP ${(i + 1).toString().padLeft(2, '0')}',
              fields: {
                'Journey':
                    '${widget.bookingDraft[i].origin} → ${widget.bookingDraft[i].destination}',
                'Seats': widget.bookingDraft[i].seats.toString(),
              },
              status: 'Ready',
            ),
          ),
        gap(20),
        ZNotice(
          'Grouped booking',
          '${widget.bookingDraft.length} trip details will be created under one booking ID.',
          color: ZColors.success,
        ),
        gap(20),
        ZButton(
          'Confirm booking',
          onPressed: widget.checkout,
          icon: Icons.arrow_forward,
        ),
      ],
    ],
  );

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
                      'BOOKING ${reservation.id} / TRIP ${reservation.detailNumber}',
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
            'On wait' => r.status == ReservationStatus.onWait,
            'Checked in' => r.status == ReservationStatus.checkedIn,
            'No show' => r.status == ReservationStatus.noShow,
            'Cancelled' => r.status == ReservationStatus.cancelled,
            _ => true,
          },
        )
        .toList();
    final bookingIds = filtered.map((r) => r.id).toSet().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          '13',
          'PASSENGER / BOOKINGS',
          'YOUR RIDES,\nGROUPED TOGETHER.',
          'Each booking groups one or more trip details. Open each QR pass, cancel one trip, or cancel every active trip under the booking ID.',
          action: ZButton(
            'Book another ride',
            onPressed: () => widget.go(ZPage.search),
            icon: Icons.arrow_forward,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['On wait', 'Checked in', 'Cancelled', 'No show', 'All']
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
        if (bookingIds.isEmpty)
          ZEmpty(
            'Nothing here yet',
            'No bookings match this filter.',
            action: ZButton(
              'Find a trip',
              onPressed: () => widget.go(ZPage.search),
            ),
          )
        else
          for (final bookingId in bookingIds)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Builder(
                builder: (context) {
                  final details = filtered
                      .where((r) => r.id == bookingId)
                      .toList();
                  final allDetails = widget.reservations
                      .where((r) => r.id == bookingId)
                      .toList();
                  final active = allDetails
                      .where((r) => r.status == ReservationStatus.onWait)
                      .toList();
                  return ZPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ZLabel(
                                    'BOOKING / $bookingId',
                                    color: ZColors.accent,
                                  ),
                                  gap(7),
                                  const ZLabel(
                                    'DATE 14 SEP 2026 / BOOKED 09:30',
                                  ),
                                ],
                              ),
                            ),
                            ZStatus(
                              '${allDetails.length} ${allDetails.length == 1 ? 'trip' : 'trips'}',
                            ),
                          ],
                        ),
                        gap(18),
                        for (final detail in details) ...[
                          const ZRule(),
                          gap(16),
                          Text(
                            '${detail.time} / ${detail.route} / TRIP ${detail.detailNumber}',
                            style: ZTheme.display(28),
                          ),
                          gap(10),
                          Text('${detail.from}  →  ${detail.to}'),
                          gap(12),
                          Wrap(
                            spacing: 9,
                            runSpacing: 9,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ZStatus(detail.status.label),
                              ZButton(
                                'View QR',
                                secondary: true,
                                compact: true,
                                onPressed: () =>
                                    widget.selectReservation(detail),
                              ),
                              if (detail.status == ReservationStatus.onWait)
                                ZButton(
                                  'Cancel trip',
                                  secondary: true,
                                  compact: true,
                                  onPressed: () => confirm(
                                    'Cancel trip ${detail.detailNumber}?',
                                    'Only this trip will be cancelled. Other trips in $bookingId stay active.',
                                    () {
                                      widget.cancel(detail);
                                      message(
                                        'Trip ${detail.detailNumber} cancelled.',
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                          gap(16),
                        ],
                        if (active.isNotEmpty) ...[
                          const ZRule(),
                          gap(16),
                          ZButton(
                            'Cancel all',
                            secondary: true,
                            compact: true,
                            onPressed: () => confirm(
                              'Cancel all trips?',
                              'Every on-wait trip in $bookingId will be cancelled and its seats released.',
                              () {
                                widget.cancelBooking(bookingId);
                                message(
                                  'All active trips in $bookingId cancelled.',
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
      ],
    );
  }

  Widget driverDayPage() {
    final assigned =
        managedSchedules
            .where(
              (schedule) =>
                  schedule.driver == 'John Driver' && schedule.isActive,
            )
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          '13',
          'DRIVER / DAILY SCHEDULE',
          'MY DRIVING\nSCHEDULE.',
          'Daily schedules where SCHEDULE.DRIVER is the signed-in driver. Driver assignment is maintained in Manage Schedules.',
          action: ZStatus('${assigned.length} SCHEDULES'),
        ),
        if (assigned.isEmpty)
          const ZEmpty(
            'No driving schedule',
            'No schedule is assigned to this driver today.',
          )
        else
          ZTable(
            headers: const ['Route', 'Time', 'Vehicle', 'Action'],
            rows: [
              for (var index = 0; index < assigned.length; index++)
                ZRecord(
                  title:
                      '${assigned[index].route} / ${managedRoutes.firstWhere((route) => route.id == assigned[index].route).name}',
                  subtitle: assigned[index].id,
                  fields: {
                    'Time':
                        '${assigned[index].time}–${scheduleArrival(assigned[index])}',
                    'Vehicle': assigned[index].plate,
                  },
                  action: index == 0
                      ? ZButton(
                          widget.tripStarted ? 'End trip' : 'Start trip',
                          compact: true,
                          onPressed: widget.tripStarted
                              ? () => confirm(
                                  'Finish the current trip?',
                                  'The trip will be closed and its passenger results summarized.',
                                  widget.onClose,
                                )
                              : widget.onStart,
                          icon: widget.tripStarted
                              ? Icons.stop_circle_outlined
                              : Icons.play_arrow,
                        )
                      : ZButton(
                          'Start trip',
                          compact: true,
                          secondary: true,
                          onPressed: widget.tripStarted ? null : widget.onStart,
                          icon: Icons.play_arrow,
                        ),
                  onTap: widget.tripStarted && index == 0
                      ? () => widget.go(ZPage.driverTrip)
                      : null,
                ),
            ],
          ),
        for (final schedule in assigned)
          timetableDisclosure(
            title: Text('${schedule.time} / See station timetable'),
            children: [scheduleStationTable(schedule)],
          ),
        if (assigned.isNotEmpty) ...[
          gap(24),
          ZButton(
            'Cancel today’s schedules',
            secondary: true,
            onPressed: () => confirm('Cancel today’s driving schedules?', 'All on-wait booking details for today will be cancelled. This also represents automatic cancellation when the driver does not show up.', () {
              final bookingIds = widget.reservations
                  .where(
                    (reservation) =>
                        reservation.status == ReservationStatus.onWait,
                  )
                  .map((reservation) => reservation.id)
                  .toSet();
              for (final bookingId in bookingIds) {
                widget.cancelBooking(bookingId);
              }
              setState(
                () => managedSchedules.removeWhere(
                  (schedule) =>
                      schedule.driver == 'John Driver' && schedule.isActive,
                ),
              );
              message('Today’s schedules and on-wait trips were cancelled.');
            }),
          ),
        ],
      ],
    );
  }

  Widget driverTripPage() {
    final driverSchedules =
        managedSchedules
            .where(
              (schedule) =>
                  schedule.driver == 'John Driver' && schedule.isActive,
            )
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    final t = driverSchedules.isEmpty ? trips[0] : driverSchedules.first;
    final route = managedRoutes.firstWhere(
      (candidate) => candidate.id == t.route,
    );
    final checkedIn = manifestStatus.values
        .where((status) => status == 'Checked in')
        .length;
    final remaining = manifestStatus.values
        .where((status) => status == 'Confirmed')
        .length;
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
            'Checked-in bookings',
            '$checkedIn',
            'Booking details verified',
          ),
          ZStat(
            'Passengers boarded',
            '${boardingCounts.values.fold<int>(0, (sum, count) => sum + count)}',
            'Actual people boarding',
          ),
          ZStat('Remaining', '$remaining', 'Awaiting status'),
        ]),
        gap(38),
        scheduleStationTable(t),
        gap(20),
        ZSectionTitle('01 / STOP SEQUENCE', 'Boarding plan'),
        for (final stop in route.stops.asMap().entries)
          ZRecord(
            title: stop.value,
            subtitle:
                'STOP ${(stop.key + 1).toString().padLeft(2, '0')} / ${stop.key == 0 ? '09:30' : '+${stop.key * 5} MIN'}',
            fields: {
              'Board': stop.key == 0
                  ? 'John Passenger (2 seats), James Passenger (1 seat)'
                  : stop.key == 1
                  ? 'Jane Passenger (1 seat)'
                  : '0 passengers',
              'Drop-off':
                  '${widget.reservations.where((b) => b.tripId == t.id && route.journeyBetween(b.from, b.to)?.destinationIndex == stop.key).fold<int>(0, (sum, b) => sum + (boardingCounts[b.token] ?? 0))} boarded passengers',
            },
            status: stop.key == 0 ? 'Current stop' : 'Upcoming',
            onTap: () => setState(() => activeStop = stop.value),
          ),
        gap(34),
        ZSectionTitle('02 / MANIFEST', 'Expected passengers'),
        for (final booking in widget.reservations.where(
          (b) => b.tripId == t.id && boardingCounts.containsKey(b.token),
        ))
          ZRecord(
            title: booking.id,
            subtitle: 'Trip ${booking.detailNumber}',
            fields: {
              'Pickup': booking.from,
              'Drop-off': booking.to,
              'Seats booked': '${booking.seats}',
              'Passengers boarded': '${boardingCounts[booking.token]}',
            },
            status: 'Checked in',
          ),
        for (final passenger in [
          ('John Passenger', 'BKG-240914-018', stops[0], stops[2], '2'),
          ('Jane Passenger', 'BKG-240914-021', stops[1], stops[3], '1'),
          ('James Passenger', 'BKG-240914-022', stops[0], stops[2], '1'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ZPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(passenger.$1, style: ZTheme.display(27)),
                      ),
                      ZStatus(manifestStatus[passenger.$1]!),
                    ],
                  ),
                  gap(12),
                  ZLabel('${passenger.$2} / ${passenger.$5} SEATS'),
                  gap(12),
                  Text('${passenger.$3} → ${passenger.$4}'),
                  if (manifestStatus[passenger.$1] == 'Confirmed') ...[
                    gap(18),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        ZButton(
                          'Scan QR',
                          compact: true,
                          onPressed: () {
                            setState(() => activeStop = passenger.$3);
                            widget.go(ZPage.checkIn);
                          },
                          icon: Icons.qr_code_scanner,
                        ),
                        ZButton(
                          'Mark no-show',
                          secondary: true,
                          compact: true,
                          onPressed: () => confirm(
                            'Mark ${passenger.$1} as no-show?',
                            'This passenger will be recorded as absent for this trip.',
                            () => setState(
                              () => manifestStatus[passenger.$1] = 'No-show',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        gap(35),
        ZButton(
          'End trip',
          onPressed: remaining == 0
              ? () => confirm(
                  'Complete this run?',
                  'End the trip and review checked-in passengers and no-shows.',
                  widget.onClose,
                )
              : null,
          icon: Icons.arrow_forward,
        ),
      ],
    );
  }

  Widget checkInPage() {
    final input = scanController.text.trim().toUpperCase();
    final booking = widget.reservations
        .where((r) => r.token.toUpperCase() == input)
        .firstOrNull;
    final result = CheckInValidator.validate(
      token: input,
      activeTripId: trips.first.id,
      activeStop: activeStop,
      reservations: widget.reservations,
      scannedTokens: boardingCounts.keys.toSet(),
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
                Text(activeStop, style: ZTheme.display(38)),
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
          hint: 'QR-BKG-240914-018-01',
          onChanged: (_) => setState(() {
            showError = false;
            boardingError = null;
            passengerCountController.clear();
          }),
        ),
        gap(13),
        const ZLabel('TRY: QR-BKG-240914-018-01 / QR-BKG-220914-007'),
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
              '${booking!.id} / Trip ${booking.detailNumber} / ${booking.seats} seats booked',
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
            ZNotice(
              'Wrong stop',
              'This booking starts at ${booking?.from}. Select that boarding station.',
              color: ZColors.accent,
              icon: Icons.error_outline,
            )
          else if (result == CheckInResult.unavailable)
            const ZNotice(
              'Check-in unavailable',
              'This booking is cancelled or marked no-show.',
              color: ZColors.accent,
            )
          else
            const ZNotice(
              'Pass not found',
              'No matching reservation token exists in this mockup.',
              color: ZColors.accent,
              icon: Icons.error_outline,
            ),
          if (booking != null) ...[
            gap(16),
            rowLabel('PICKUP', booking.from),
            gap(12),
            rowLabel('DROP-OFF', booking.to),
            gap(12),
            rowLabel('SEATS BOOKED', '${booking.seats}'),
            if (boardingCounts.containsKey(booking.token)) ...[
              gap(12),
              rowLabel(
                'PASSENGERS BOARDED',
                '${boardingCounts[booking.token]}',
              ),
            ],
          ],
          if (result == CheckInResult.accepted) ...[
            gap(16),
            ZField(
              'Passengers boarding',
              controller: passengerCountController,
              hint: 'Actual number boarding (1–${booking!.seats})',
              onChanged: (_) => setState(() => boardingError = null),
            ),
            gap(10),
            const Text(
              'Enter the actual people boarding. Booked seats remain unchanged.',
            ),
            if (boardingError != null)
              Text(
                boardingError!,
                style: const TextStyle(color: ZColors.accent),
              ),
            gap(16),
            ZButton(
              'Confirm boarding',
              onPressed: () {
                final count = int.tryParse(
                  passengerCountController.text.trim(),
                );
                try {
                  CheckInValidator.validatePassengerCount(
                    count ?? 0,
                    booking.seats,
                  );
                  widget.onBoard?.call(booking, count!);
                } on BookingValidationException catch (error) {
                  setState(() => boardingError = error.message);
                  return;
                }
                setState(() {
                  boardingCounts[booking.token] = count!;
                  if (booking.id == 'BKG-240914-018') {
                    manifestStatus['John Passenger'] = 'Checked in';
                  }
                });
                widget.onScan();
                widget.go(ZPage.driverTrip);
              },
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
        const ZStat('Seats booked', '06', 'Reserved seats'),
        ZStat(
          'Passengers boarded',
          '${boardingCounts.values.fold<int>(0, (sum, count) => sum + count)}',
          'Actual people boarding',
        ),
        ZStat(
          'Checked in',
          manifestStatus.values
              .where((status) => status == 'Checked in')
              .length
              .toString(),
          'Boarded successfully',
        ),
        ZStat(
          'No-shows',
          manifestStatus.values
              .where((status) => status == 'No-show')
              .length
              .toString(),
          'Reserved but absent',
        ),
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
      for (final passenger in manifestStatus.entries.where(
        (entry) => entry.value == 'No-show',
      ))
        ZRecord(
          title: passenger.key,
          subtitle: 'PASSENGER MANIFEST',
          fields: const {'Reason': 'Marked absent by driver'},
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
      'Trip log',
      'Booked trips',
      'Route demand',
      'Driver activity',
      'Vehicle utilization',
    ];
    final data = switch (report) {
      'Trip log' => [6, 5, 4, 7, 6, 4, 3],
      'Booked trips' => [86, 74, 12, 8, 5, 3, 0],
      'Route demand' => [285, 275, 310, 295, 340, 190, 170],
      'Driver activity' => [25, 20, 18, 15, 12, 10, 0],
      _ => [63, 37, 20, 0, 0, 0, 0],
    };
    final labels = switch (report) {
      'Route demand' => ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'],
      'Driver activity' => ['SOM', 'SOMM', 'SOMK', 'ARE', 'WAR', 'NAN', ''],
      'Vehicle utilization' => ['VAN', 'BUS', 'MINI', '', '', '', ''],
      'Booked trips' => ['BOOK', 'SEAT', 'CXL', 'SCAN', 'NO-SHOW', '', ''],
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
        if (report == 'Booked trips') ...[
          gap(26),
          ZSectionTitle('ADMIN REVIEW', 'Daily booking details'),
          for (final booking in widget.reservations.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ZRecord(
                title: '${booking.id} / NO ${booking.detailNumber}',
                subtitle: '${booking.route} ${booking.time}',
                fields: {
                  'Journey': '${booking.from} → ${booking.to}',
                  'Seats': booking.seats.toString(),
                },
                status: booking.status.label,
                onTap: booking.status == ReservationStatus.onWait
                    ? () => confirm(
                        'Cancel this booked trip?',
                        'Administration will cancel only this booking detail.',
                        () => widget.cancel(booking),
                      )
                    : null,
              ),
            ),
        ],
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
              Text(
                '${profileName.text} ${profileLastName.text}'.toUpperCase(),
                style: ZTheme.display(35),
              ),
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
                ZRole.admin => 'EP002 / OPERATIONS MANAGER',
                ZRole.passenger => 'PP001 / STUDENT',
                ZRole.driver => 'EP001 / DRIVER',
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
                'First name',
                controller: profileName,
                onChanged: (_) => setState(() {}),
              ),
              gap(20),
              ZField(
                'Last name',
                controller: profileLastName,
                onChanged: (_) => setState(() {}),
              ),
              gap(20),
              ZField(
                'Institutional email',
                controller: profileEmail,
                onChanged: (_) => setState(() {}),
              ),
              gap(20),
              ZSelect(
                widget.role == ZRole.passenger
                    ? 'Passenger department'
                    : 'Employee department · locked',
                value: widget.role == ZRole.passenger
                    ? accountDepartment
                    : widget.role == ZRole.driver
                    ? 'ED001 / Transport'
                    : 'ED002 / Management',
                items: widget.role == ZRole.passenger
                    ? const [
                        'PD001 / Technology',
                        'PD002 / Computer Science',
                        'PD003 / Civil Engineering',
                        'PD004 / Multimedia',
                        'PD005 / Architecture',
                        'PD006 / Business',
                      ]
                    : const ['ED001 / Transport', 'ED002 / Management'],
                onChanged: widget.role == ZRole.passenger
                    ? (value) => setState(
                        () => accountDepartment = value ?? accountDepartment,
                      )
                    : null,
              ),
              gap(20),
              ZSelect(
                widget.role == ZRole.passenger
                    ? 'Passenger position'
                    : 'Employee position · locked',
                value: widget.role == ZRole.passenger
                    ? accountPosition
                    : widget.role == ZRole.driver
                    ? 'EP001 / Driver'
                    : 'EP002 / Operations manager',
                items: widget.role == ZRole.passenger
                    ? const [
                        'PP001 / Student',
                        'PP002 / Teaching Assistant',
                        'PP003 / Teacher',
                        'PP004 / Guest',
                      ]
                    : const [
                        'EP001 / Driver',
                        'EP002 / Operations manager',
                        'EP003 / Admin',
                      ],
                onChanged: widget.role == ZRole.passenger
                    ? (value) => setState(
                        () => accountPosition = value ?? accountPosition,
                      )
                    : null,
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
