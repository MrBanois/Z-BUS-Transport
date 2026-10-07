import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/report_repository.dart';
import '../presentation/shared/report_view.dart';
import 'report_spec.dart';

/// Drives the statistic reports screen.
///
/// One controller for all the reports rather than one per report, because what
/// they share is the whole lifecycle — pick a report, fill in its own
/// parameters, run it, switch how it is drawn, export it — and five controllers
/// would have to agree about every rule in here. What they do not share is the
/// descriptor in [reports], which is where the differences live.
class ReportsController extends ChangeNotifier {
  ReportsController({
    ReportRepository? repository,
    List<ReportSpec>? reports,
  }) : _repository = repository ?? ReportRepository(),
       _reports = reports ?? kReportSpecs {
    if (_reports.isEmpty) {
      throw ArgumentError.value(reports, 'reports', 'cannot be empty');
    }
    _spec = _reports.first;
    _values = _spec.defaults;
  }

  final ReportRepository _repository;
  final List<ReportSpec> _reports;

  late ReportSpec _spec;
  late Map<String, Object?> _values;
  Map<String, String> _errors = const {};
  ReportView? _view;
  String? _error;
  String? _notice;
  bool _loading = false;
  int _chartIndex = 0;

  /// Repository exposed so a host can build sibling repositories against the
  /// same `ApiClient`; otherwise a build pointed at another server would fetch
  /// reports from one host and route names from another.
  ReportRepository get repository => _repository;

  List<ReportSpec> get reports => _reports;

  ReportSpec get spec => _spec;

  Map<String, Object?> get values => _values;

  /// Rejections to render under their inputs.
  Map<String, String> get errors => _errors;

  /// The last completed run, or null before the first.
  ReportView? get view => _view;

  /// A failure with nothing to show it beside.
  String? get error => _error;

  /// A success worth mentioning: an export written, mostly.
  String? get notice => _notice;

  /// A run is in flight.
  bool get loading => _loading;

  /// Which of the report's views is on screen.
  int get chartIndex => _chartIndex;

  /// True while there is nothing to export. The page treats a disabled button
  /// as an explanation, so this has to count "loaded, but empty" as exportable
  /// — an empty table is still a report about a quiet month.
  bool get hasOutput => _view != null;

  /// Switch to another report.
  ///
  /// Parameters are re-seeded from that report's own defaults and the previous
  /// result is dropped: showing last month's chart under a different report's
  /// heading would be a report about something nobody asked for.
  void select(String id) {
    ReportSpec? found;
    for (final candidate in _reports) {
      if (candidate.id == id) {
        found = candidate;
        break;
      }
    }
    if (found == null || found.id == _spec.id) return;
    _spec = found;
    _values = found.defaults;
    _errors = const {};
    _view = null;
    _error = null;
    _chartIndex = 0;
    notifyListeners();
  }

  /// Record an edit to one parameter, clearing that field's stale rejection.
  ///
  /// A change that moves nothing is ignored so a field re-reporting the same
  /// characters does not rebuild the screen on every keystroke.
  void set(String field, Object? value) {
    if (_values[field] == value) return;
    _values = {..._values, field: value};
    if (_errors.containsKey(field)) {
      _errors = Map.of(_errors)..remove(field);
    }
    notifyListeners();
  }

  /// Switch between the report's own views: pickup and drop-off, bar and pie.
  void showChart(int index) {
    if (_chartIndex == index) return;
    _chartIndex = index;
    notifyListeners();
  }

  /// Validate, then fetch.
  ///
  /// A previous result stays on screen while a new run is in flight and after
  /// one fails. Blanketing a chart the reader was looking at, because a retry
  /// did not come back, would cost them information to report that they already
  /// have it.
  Future<void> run() async {
    if (_loading) return;

    final problems = _spec.validate(_values);
    if (problems.isNotEmpty) {
      _errors = problems;
      notifyListeners();
      return;
    }

    _loading = true;
    _errors = const {};
    _error = null;
    notifyListeners();

    try {
      final result = await _spec.run(_repository, _values);
      _view = result;
      if (_chartIndex >= result.charts.length) _chartIndex = 0;
    } on ApiException catch (e) {
      // A rejection naming an input this screen renders goes under that input.
      // Anything else stays a banner: better to show a message beside no field
      // than to drop it.
      if (e.field != null && _spec.fieldKeys.contains(e.field)) {
        _errors = {e.field!: e.message};
      } else {
        _error = e.message;
      }
    } catch (_) {
      _error = 'Something went wrong generating this report.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Record what an export did, for the page to show as a banner.
  void announce(String message) {
    _notice = message;
    notifyListeners();
  }

  /// Record an export that did not happen.
  void announceFailure(String message) {
    _error = message;
    notifyListeners();
  }

  void dismiss() {
    if (_error == null && _notice == null) return;
    _error = null;
    _notice = null;
    notifyListeners();
  }
}
