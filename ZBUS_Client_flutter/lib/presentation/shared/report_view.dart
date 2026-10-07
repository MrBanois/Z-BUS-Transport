/// What a statistic report screen draws, in shapes the presentation can render
/// without knowing anything about SQL, endpoints, dates or which report this is.
///
/// Everything here arrives as data from the app layer: the descriptors in
/// `app/report_spec.dart` decide which columns are the x-axis, which are series
/// and which stay in the table alone, then build these. Nothing in this file
/// knows what a booking or a route is.
library;

/// How a report's chart is drawn.
///
/// A report may offer both -- user behaviour switches between a bar chart and a
/// pie of its totals -- which is why the choice is data rather than a widget
/// type chosen when the screen is written.
enum ChartKind { bar, pie }

/// One legend entry: a name and one value per [ChartView.categories].
class ChartSeries {
  const ChartSeries({required this.label, required this.values});

  /// What to write beside the swatch.
  final String label;

  /// Aligned with [ChartView.categories]: `values[i]` belongs to
  /// `categories[i]`.
  final List<double> values;
}

/// One selectable way of drawing a report.
class ChartView {
  const ChartView({
    required this.label,
    required this.kind,
    required this.categories,
    required this.series,
    this.yAxisLabel = '',
  });

  /// The switch's wording: `Pickup`, `Drop-off`, `Bars`, `Pie`.
  ///
  /// A label rather than an id because with two or three choices it is the only
  /// thing the user reads, and it says which view is which.
  final String label;

  final ChartKind kind;

  /// Bar: the groups along the x-axis. Pie: the labels beside each slice.
  final List<String> categories;

  /// One entry per legend item, in legend order.
  ///
  /// For a bar chart that is one entry per series. For a pie there is exactly
  /// one, and its [ChartSeries.values] are the slice sizes -- a pie has a
  /// single set of numbers split into parts, not a set per category, and
  /// pretending otherwise would give a legend that repeated itself.
  final List<ChartSeries> series;

  /// Y-axis title, drawn above the chart. Empty for a pie, which has no axes
  /// to title.
  final String yAxisLabel;

  /// The slice sizes a pie draws, one per [categories].
  List<double> get slices =>
      series.isEmpty ? const <double>[] : series.first.values;
}

/// One report the picker offers, reduced to what the picker shows.
///
/// Its own small shape rather than the report's own descriptor: the page is
/// given a list of names and ids to render and a callback to call, and letting
/// it reach for the descriptor would mean importing how a report is run into a
/// file that only decides where things go.
class ReportChoice {
  const ReportChoice(this.id, this.name);
  final String id;
  final String name;
}

/// Everything one run of a report shows, already aggregated.
///
/// Chart above table is the screen's rule, and both are built from the same
/// records so they cannot disagree: a chart that showed a total its own table
/// did not contain would be worse than no chart.
class ReportView {
  const ReportView({
    required this.dateRange,
    required this.columns,
    required this.rows,
    required this.charts,
  });

  /// What the server says was covered, as display text.
  final String dateRange;

  /// Table header, left to right.
  final List<String> columns;

  /// Table body, each row aligned with [columns].
  final List<List<Object?>> rows;

  /// At least one. The screen offers a switch only when there is a choice.
  final List<ChartView> charts;

  /// Which chart to show when [charts] is indexed by [selectedIndex].
  ChartView chartAt(int selectedIndex) {
    if (charts.isEmpty) {
      throw StateError('A report view always has at least one chart.');
    }
    final index = selectedIndex.clamp(0, charts.length - 1);
    return charts[index];
  }
}
