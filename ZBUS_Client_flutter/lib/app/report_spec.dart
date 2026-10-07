import '../data/report_repository.dart';
import '../presentation/shared/report_view.dart';
import '../presentation/shared/ui_fields.dart';

// =============================================================================
// Parameter keys
// =============================================================================

// Named after the API's own body keys rather than in a client dialect, so a
// rejection the server reports against `end_date` lands under the input that
// sent it with no mapping to keep in step.
const String kYearField = 'year';
const String kStartField = 'start_date';
const String kEndField = 'end_date';

// =============================================================================
// Vocabulary
// =============================================================================

/// The twelve months, in calendar order, as the reports spell them.
///
/// The server deliberately does not: its query used to ask Oracle for month
/// names and got them back in whatever language the session's NLS settings
/// said, so English names were a database configuration away from being Thai.
/// The list lives here instead.
const List<String> kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// The same months as the chart's x-axis labels. Twelve full names across the
/// width of a chart would collide even once rotated; the table below carries
/// the same words in full, so nothing is lost.
const List<String> kMonthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Weekdays, Monday first, in the order report 4 returns them.
const List<String> kWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

// =============================================================================
// Parameters
// =============================================================================

/// Which controls a report asks for.
///
/// There is no shared "report options" form. A year report has no dates and a
/// range report has no year, and showing a control that changes nothing is
/// worse than showing none, so each report declares its own.
enum ReportParamKind { year, dateRange }

/// One thing a report needs before it can be run.
class ReportParam {
  const ReportParam.year() : kind = ReportParamKind.year;

  const ReportParam.dateRange() : kind = ReportParamKind.dateRange;

  final ReportParamKind kind;

  /// The inputs this parameter puts on the screen.
  List<UiFieldSpec> get fields => switch (kind) {
    ReportParamKind.year => [
      UiFieldSpec(
        kYearField,
        'Year',
        kind: UiFieldKind.number,
        hint: '${DateTime.now().year}',
        help: 'January to December of that year.',
      ),
    ],
    ReportParamKind.dateRange => const [
      UiFieldSpec(
        kStartField,
        'From',
        kind: UiFieldKind.date,
        hint: 'YYYY-MM-DD',
      ),
      UiFieldSpec(
        kEndField,
        'To',
        kind: UiFieldKind.date,
        hint: 'YYYY-MM-DD',
        help: 'Both days are counted.',
      ),
    ],
  };

  /// What the inputs are pre-filled with when this report is first selected.
  ///
  /// Pre-filled rather than blank so the report runs on arrival. A blank form
  /// would open on an error about a year nobody has typed yet.
  Map<String, Object?> get defaults {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (kind) {
      ReportParamKind.year => {kYearField: '${now.year}'},
      ReportParamKind.dateRange => {
        kStartField: isoDate(today.subtract(const Duration(days: 30))),
        kEndField: isoDate(today),
      },
    };
  }

  /// Field-keyed problems with [values]. Empty means the request may go.
  Map<String, String> validate(Map<String, Object?> values) => switch (kind) {
    ReportParamKind.year => _validateYear(values),
    ReportParamKind.dateRange => _validateRange(values),
  };
}

Map<String, String> _validateYear(Map<String, Object?> values) {
  final raw = '${values[kYearField] ?? ''}'.trim();
  if (raw.isEmpty) return const {kYearField: 'Enter a year.'};
  final year = int.tryParse(raw);
  // Four digits, not an arbitrary window: the server builds a `date` straight
  // from this, and anything outside 1000-9999 is a server error rather than an
  // empty report. Matching the four-digit rule means the message is true.
  if (year == null || year < 1000 || year > 9999) {
    return const {kYearField: 'Enter a four-digit year.'};
  }
  return const {};
}

Map<String, String> _validateRange(Map<String, Object?> values) {
  final errors = <String, String>{};

  DateTime? parse(String key) {
    final raw = '${values[key] ?? ''}'.trim();
    if (!kIsoDatePattern.hasMatch(raw)) {
      errors[key] = 'Use the format YYYY-MM-DD.';
      return null;
    }
    return DateTime.parse(raw);
  }

  final start = parse(kStartField);
  final end = parse(kEndField);

  // Checked here as well as on the server so the common mistake is caught
  // before a round trip. The server keeps its own copy of the rule because it
  // is the API's guarantee, not this screen's.
  if (start != null && end != null && end.isBefore(start)) {
    errors[kEndField] = 'The end cannot come before the start.';
  }
  return errors;
}

// =============================================================================
// The five reports the screen offers
// =============================================================================

/// One statistic report: what it is called, what it needs, and how to build a
/// screen out of what comes back.
///
/// Each report is its own descriptor rather than rows of a config table. The
/// five differ in which columns are the x-axis, which are series, which stay in
/// the table alone and which get a second view — differences that are code, not
/// data, and that a table of strings would only relocate.
///
/// The server also serves `/report7` (trips per vehicle); the screen
/// deliberately does not offer it, which is why there are five descriptors
/// and not six.
class ReportSpec {
  const ReportSpec({
    required this.id,
    required this.name,
    required this.summary,
    required this.params,
    required this.fileSlug,
    required this.run,
  });

  /// Stable identity, used to keep the picker's selection across rebuilds.
  final String id;

  /// What it is called on the screen and in exported files.
  final String name;

  /// One line about what the report answers.
  final String summary;

  /// Its own parameters, in the order they are laid out.
  final List<ReportParam> params;

  /// The exported files' stem: `zbus-station-usage-2026-10-07.png`.
  final String fileSlug;

  /// Fetch and shape. [values] has already passed [validate].
  final Future<ReportView> Function(
    ReportRepository repository,
    Map<String, Object?> values,
  ) run;

  /// Every input this report puts on screen, in layout order.
  List<UiFieldSpec> get fields => [for (final p in params) ...p.fields];

  Map<String, Object?> get defaults => {
    for (final p in params) ...p.defaults,
  };

  /// The field names a server rejection may name, so one lands under its input.
  Set<String> get fieldKeys => {for (final f in fields) f.name};

  Map<String, String> validate(Map<String, Object?> values) {
    final errors = <String, String>{};
    for (final param in params) {
      errors.addAll(param.validate(values));
    }
    return errors;
  }
}

// =============================================================================
// Parameter readers
// =============================================================================

// Called only after `validate`, so these cannot fail to parse.
int _year(Map<String, Object?> values) => int.parse(_text(values[kYearField]));

DateTime _start(Map<String, Object?> values) =>
    DateTime.parse(_text(values[kStartField]));

DateTime _end(Map<String, Object?> values) =>
    DateTime.parse(_text(values[kEndField]));

String _text(Object? value) => '${value ?? ''}'.trim();

/// A count. Anything that is not a number reads as zero rather than throwing,
/// so one malformed cell costs one bar instead of the whole report.
num _num(Object? value) => value is num ? value : 0;

/// The column order report 4 returned, which is the server's own ordering of
/// active and used routes rather than anything this screen can predict.
List<String> _routeIds(List<Map<String, Object?>> rows) {
  if (rows.isEmpty) return const [];
  return [for (final key in rows.first.keys) if (key != 'Day') key];
}

// =============================================================================
// Shapes
// =============================================================================

/// `/api/report1` — pickups and dropoffs at every station, for one year.
///
/// The table carries both series side by side because that is how the figures
/// are read; the chart switches between them because a hundred bars in one
/// plot, ten stations by twelve months, would say less than either half alone.
ReportView _stationUsage(ReportPayload payload) {
  final columns = <String>['Station'];
  for (final month in kMonthShort) {
    columns
      ..add('$month Pickup')
      ..add('$month Drop-off');
  }

  ChartView byMonth(String label, String key) => ChartView(
    label: label,
    kind: ChartKind.bar,
    categories: kMonthShort,
    yAxisLabel: 'Passengers',
    series: [
      for (final row in payload.data)
        ChartSeries(
          label: _text(row['Station']),
          values: [
            for (final month in kMonthNames) _num(row['${key}_$month']).toDouble(),
          ],
        ),
    ],
  );

  return ReportView(
    dateRange: payload.dateRange,
    columns: columns,
    rows: [
      for (final row in payload.data)
        [
          _text(row['Station']),
          for (final month in kMonthNames) ...[
            _num(row['Pickup_$month']),
            _num(row['Dropoff_$month']),
          ],
        ],
    ],
    charts: [byMonth('Pickup', 'Pickup'), byMonth('Drop-off', 'Dropoff')],
  );
}

/// `/api/report2` — bookings per month, split by how they ended.
///
/// `Bookings` and `Seats` are table-only. The chart shows the three outcomes,
/// because those are what vary shape across a year; totals vary only in size
/// and a bar for them would tell the reader nothing the row below does not.
ReportView _bookingStatus(ReportPayload payload) => ReportView(
  dateRange: payload.dateRange,
  columns: const [
    'Month',
    'Total booking',
    'Seat booked',
    'Cancelled',
    'Check-in',
    'No show',
  ],
  rows: [
    for (final row in payload.data)
      [
        _text(row['Month']),
        _num(row['Bookings']),
        _num(row['Seats']),
        _num(row['Cancelled']),
        _num(row['Checked-In']),
        _num(row['No-Show']),
      ],
  ],
  charts: [
    ChartView(
      label: 'By outcome',
      kind: ChartKind.bar,
      categories: kMonthShort,
      yAxisLabel: 'Bookings',
      series: [
        ChartSeries(
          label: 'Check-in',
          values: [for (final row in payload.data) _num(row['Checked-In']).toDouble()],
        ),
        ChartSeries(
          label: 'Cancelled',
          values: [for (final row in payload.data) _num(row['Cancelled']).toDouble()],
        ),
        ChartSeries(
          label: 'No show',
          values: [for (final row in payload.data) _num(row['No-Show']).toDouble()],
        ),
      ],
    ),
  ],
);

/// `/api/report3` — what each user did over a date range.
///
/// Two views. The bar chart keeps every user separate so the heavy bookers
/// stand out; the pie throws the names away and adds the three outcomes
/// together, which is the only way to read "how do bookings end overall" — a
/// pie with a slice per user would be the bar chart in a circle.
ReportView _userBehaviour(ReportPayload payload) {
  const outcomes = <String>['Check-in', 'Cancelled', 'No show'];
  const keys = <String>['Checked-In', 'Cancelled', 'No-Show'];

  num totalOf(String key) {
    num total = 0;
    for (final row in payload.data) {
      total += _num(row[key]);
    }
    return total;
  }

  return ReportView(
    dateRange: payload.dateRange,
    columns: const ['User', 'Total booking', 'Check-in', 'Cancelled', 'No show'],
    rows: [
      for (final row in payload.data)
        [
          _text(row['User']),
          _num(row['Bookings']),
          _num(row['Checked-In']),
          _num(row['Cancelled']),
          _num(row['No-Show']),
        ],
    ],
    charts: [
      ChartView(
        label: 'By user',
        kind: ChartKind.bar,
        categories: [for (final row in payload.data) _text(row['User'])],
        yAxisLabel: 'Bookings',
        series: [
          ChartSeries(
            label: 'Total booking',
            values: [for (final row in payload.data) _num(row['Bookings']).toDouble()],
          ),
          ChartSeries(
            label: 'Check-in',
            values: [for (final row in payload.data) _num(row['Checked-In']).toDouble()],
          ),
          ChartSeries(
            label: 'Cancelled',
            values: [for (final row in payload.data) _num(row['Cancelled']).toDouble()],
          ),
          ChartSeries(
            label: 'No show',
            values: [for (final row in payload.data) _num(row['No-Show']).toDouble()],
          ),
        ],
      ),
      ChartView(
        label: 'All users',
        kind: ChartKind.pie,
        categories: outcomes,
        yAxisLabel: 'Bookings',
        series: [ChartSeries(label: 'Bookings', values: [
          for (final key in keys) totalOf(key).toDouble(),
        ])],
      ),
    ],
  );
}

/// `/api/report4` — passengers per route, by day of the week.
///
/// The columns are route ids until [names] translates them. `/api/route` is
/// fetched alongside the report rather than on every run because this is the
/// only report whose keys are references; the rest already come back as words.
ReportView _routeUsage(
  ReportPayload payload,
  Map<String, String> names,
) {
  final ids = _routeIds(payload.data);

  // A route the reference list has missed keeps its id rather than a blank
  // heading: `R0011` says which route, an empty cell says nothing.
  String labelOf(String id) {
    final name = names[id];
    return name == null || name.isEmpty ? id : name;
  }

  final labels = {for (final id in ids) id: labelOf(id)};

  // Looked up by day rather than kept in row order. The report is seven rows
  // tall whether or not the server had anything for every weekday: aligning
  // bars to `Monday..Sunday` by position would silently put Tuesday's count on
  // Monday's bar the first time a quiet day changes the row count.
  final byDay = {for (final row in payload.data) _text(row['Day']): row};

  return ReportView(
    dateRange: payload.dateRange,
    columns: ['Day', ...ids.map((id) => labels[id]!)],
    rows: [
      for (final day in kWeekdays)
        [day, ...ids.map((id) => _num(byDay[day]?[id]))],
    ],
    charts: [
      ChartView(
        label: 'By route',
        kind: ChartKind.bar,
        categories: kWeekdays,
        yAxisLabel: 'Passengers',
        series: [
          for (final id in ids)
            ChartSeries(
              label: labels[id]!,
              values: [
                for (final day in kWeekdays) _num(byDay[day]?[id]).toDouble(),
              ],
            ),
        ],
      ),
    ],
  );
}

/// `/api/report6` — each driver's trips over a date range, split at 17:00.
///
/// The table carries all three counts because that is how the figures are
/// read; the chart draws only the two halves, which add up to the total —
/// drawing all three would give every driver a bar twice as tall as its own
/// parts. The driver's id stays in the table because two drivers can share a
/// name, and a row nobody can tell apart from another is a row that cannot
/// be followed up.
ReportView _driverSchedule(ReportPayload payload) => ReportView(
  dateRange: payload.dateRange,
  columns: const ['Driver', 'Driver ID', 'Total', 'Before 17:00', 'After 17:00'],
  rows: [
    for (final row in payload.data)
      [
        _text(row['Name']),
        _text(row['Driver_ID']),
        _num(row['Total']),
        _num(row['Before_17']),
        _num(row['After_17']),
      ],
  ],
  charts: [
    ChartView(
      label: 'By driver',
      kind: ChartKind.bar,
      categories: [for (final row in payload.data) _text(row['Name'])],
      yAxisLabel: 'Trips',
      series: [
        ChartSeries(
          label: 'Before 17:00',
          values: [
            for (final row in payload.data) _num(row['Before_17']).toDouble(),
          ],
        ),
        ChartSeries(
          label: 'After 17:00',
          values: [
            for (final row in payload.data) _num(row['After_17']).toDouble(),
          ],
        ),
      ],
    ),
  ],
);

// =============================================================================
// The list
// =============================================================================

/// Every report the screen offers, in the order it offers them.
///
/// `final` and not `const`: each entry carries a closure that knows how to run
/// it, and a list of closures cannot be const. The order is the order of the
/// conversation — what happened, then to bookings, then to people, then out to
/// the network and the drivers.
final List<ReportSpec> kReportSpecs = [
  ReportSpec(
    id: 'station-usage',
    name: 'Station usage',
    summary: 'Passengers picked up and dropped off at every station, by month.',
    params: const [ReportParam.year()],
    fileSlug: 'station-usage',
    run: (repository, values) async => _stationUsage(
      await repository.stationUsage(year: _year(values)),
    ),
  ),
  ReportSpec(
    id: 'booking-status',
    name: 'Booking status',
    summary: "Bookings, seats and how every month's bookings ended.",
    params: const [ReportParam.year()],
    fileSlug: 'booking-status',
    run: (repository, values) async => _bookingStatus(
      await repository.bookingStatus(year: _year(values)),
    ),
  ),
  ReportSpec(
    id: 'user-behaviour',
    name: 'User behaviour',
    summary: 'What each user booked, checked in, cancelled or missed.',
    params: const [ReportParam.dateRange()],
    fileSlug: 'user-behaviour',
    run: (repository, values) async => _userBehaviour(
      await repository.userBehaviour(start: _start(values), end: _end(values)),
    ),
  ),
  ReportSpec(
    id: 'route-usage',
    name: 'Route usage',
    summary: 'Passengers on each route, by day of the week.',
    params: const [ReportParam.dateRange()],
    fileSlug: 'route-usage',
    run: (repository, values) async {
      final payload = await repository.routeUsage(
        start: _start(values),
        end: _end(values),
      );
      return _routeUsage(payload, await repository.routeNames());
    },
  ),
  ReportSpec(
    id: 'driver-schedule',
    name: 'Driver schedule',
    summary: 'Trips each driver ran, split before and after 17:00.',
    params: const [ReportParam.dateRange()],
    fileSlug: 'driver-schedule',
    run: (repository, values) async => _driverSchedule(
      await repository.driverSchedule(start: _start(values), end: _end(values)),
    ),
  ),
];
