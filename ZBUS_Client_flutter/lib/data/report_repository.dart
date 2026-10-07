import 'api_client.dart';

/// One report as the server produced it: the range it covered and its flat
/// records.
///
/// Carries no idea what the columns mean. Which of them are x-axis categories,
/// which are series and which exist only in the table is a property of the
/// report, so it belongs to the descriptors that describe reports rather than
/// to the type that ferries them about.
class ReportPayload {
  ReportPayload({this.dateRange = '', this.data = const []});

  factory ReportPayload.fromJson(Map<String, dynamic> json) => ReportPayload(
    dateRange: '${json['date_range'] ?? ''}'.trim(),
    data: [
      for (final row in json['data'] as List? ?? const [])
        if (row is Map<String, dynamic>) Map<String, Object?>.from(row),
    ],
  );

  /// What the server says was covered, already formatted for display.
  ///
  /// Display text rather than parsed bounds: the screen shows it and has no
  /// need to do arithmetic on it, and re-parsing a string the server chose the
  /// format of would only be a second thing to get wrong.
  final String dateRange;

  final List<Map<String, Object?>> data;

  bool get isEmpty => data.isEmpty;
}

/// The statistic reports, addressed by what they report.
///
/// The names are the reports', not their route numbers. The screen offers five
/// of the six: `/report7` (trips per vehicle) is served by the API but
/// deliberately not offered in the interface, and there is no `/report5` at
/// all, so calling `report7(...)` from a screen would leave a reader to work
/// out which report that was.
///
/// Every method is a read. Nothing here can change the database.
class ReportRepository {
  ReportRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  /// `/api/report1`. One year: pickups and dropoffs at every station.
  Future<ReportPayload> stationUsage({required int year}) =>
      _report(_api.reportStationUsage(year: year));

  /// `/api/report2`. One year: bookings per month, split by status.
  Future<ReportPayload> bookingStatus({required int year}) =>
      _report(_api.reportBookingStatus(year: year));

  /// `/api/report3`. A date range: what each user did.
  Future<ReportPayload> userBehaviour({
    required DateTime start,
    required DateTime end,
  }) => _report(_api.reportUserBehaviour(start: start, end: end));

  /// `/api/report4`. A date range: passengers per route, by weekday.
  ///
  /// Column keys come back as route ids, so [routeNames] is needed to put
  /// something recognisable on the table and the legend.
  Future<ReportPayload> routeUsage({
    required DateTime start,
    required DateTime end,
  }) => _report(_api.reportRouteUsage(start: start, end: end));

  /// `/api/route`. Id to name, for labelling route usage's columns.
  ///
  /// Only report 4 needs it: every other report's columns are already words
  /// the database wrote, so this is fetched by the one report that asks for it
  /// rather than on every run.
  Future<Map<String, String>> routeNames() async => {
    for (final row in await _api.routes())
      _pad(row['id']): '${row['name'] ?? ''}'.trim(),
  };

  /// `/api/report6`. A date range: each driver's trips around 17:00.
  Future<ReportPayload> driverSchedule({
    required DateTime start,
    required DateTime end,
  }) => _report(_api.reportDriverSchedule(start: start, end: end));

  /// `/api/report7`. A date range: trips per vehicle.
  Future<ReportPayload> vehicleTrips({
    required DateTime start,
    required DateTime end,
  }) => _report(_api.reportVehicleTrips(start: start, end: end));

  Future<ReportPayload> _report(Future<Map<String, dynamic>> call) async =>
      ReportPayload.fromJson(await call);

  /// CHAR columns come back from Oracle space-padded, and `S0001 ` is not the
  /// same key as `S0001` when two requests disagree about it.
  static String _pad(Object? value) => '${value ?? ''}'.trim();
}
