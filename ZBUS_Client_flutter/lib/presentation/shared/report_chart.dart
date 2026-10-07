import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'design_system.dart';
import 'report_view.dart';

/// Draws one [ChartView].
///
/// Colours come from [ZColors.series] using the same index the legend uses, so
/// bar number three is the same colour in both. That pairing is the entire
/// reason the legend exists and it only holds while both sides ask for the
/// same index.
class ZReportChart extends StatelessWidget {
  const ZReportChart(this.chart, {super.key, this.height = 330});

  final ChartView chart;

  /// Fixed rather than intrinsic: a chart that resized when the legend wrapped
  /// would push the table around on every year change.
  final double height;

  @override
  Widget build(BuildContext context) => Column(
    // Min, not the default: the page scrolls, so this has to size itself from
    // its children instead of trying to claim the scroll view's unbounded
    // height.
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (chart.yAxisLabel.isNotEmpty) ...[
        ZLabel(chart.yAxisLabel),
        const SizedBox(height: 16),
      ],
      SizedBox(
        height: height,
        child: switch (chart.kind) {
          ChartKind.bar => _BarChart(chart),
          ChartKind.pie => _PieChart(chart),
        },
      ),
    ],
  );
}

class _BarChart extends StatelessWidget {
  const _BarChart(this.chart);

  final ChartView chart;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = chart.categories.length;
      if (count == 0 || chart.series.isEmpty) return const SizedBox.shrink();

      // Longest label decides the treatment for every label: mixing rotated and
      // horizontal names under one chart reads as a mistake rather than a
      // considered layout.
      var longest = 0;
      for (final label in chart.categories) {
        longest = math.max(longest, label.length);
      }
      final rotate = count > 8 || longest > 10;
      final slot = constraints.maxWidth / count;

      var highest = 0.0;
      for (final series in chart.series) {
        for (final value in series.values) {
          highest = math.max(highest, value);
        }
      }
      // A chart of nothing still has to draw an axis. Without a ceiling fl_chart
      // would scale to zero and paint every gridline on top of the baseline.
      final ceiling =
          highest <= 0 ? 1.0 : (highest + math.max(1, highest * .1)).ceilToDouble();

      return BarChart(
        BarChartData(
          maxY: ceiling,
          barGroups: [
            for (var x = 0; x < count; x++)
              BarChartGroupData(
                x: x,
                barsSpace: 1,
                barRods: [
                  for (var s = 0; s < chart.series.length; s++)
                    BarChartRodData(
                      toY: _at(chart.series[s].values, x),
                      color: ZColors.series(s),
                      width: _rodWidth(slot, chart.series.length),
                      // Squared: the rest of the interface is hairline boxes and
                      // a rounded bar would be the one soft corner on the screen.
                      borderRadius: BorderRadius.zero,
                    ),
                ],
              ),
          ],
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: rotate ? 116 : 30,
                getTitlesWidget: (value, meta) =>
                    _category(value, slot, rotate),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    // Counts are whole; printing 2.0 beside a bar two units tall
                    // is noise the grid did not need.
                    value == value.roundToDouble()
                        ? value.toInt().toString()
                        : value.toStringAsFixed(1),
                    textAlign: TextAlign.right,
                    style: ZTheme.mono(10),
                  ),
                ),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => ZColors.surface2,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    '${_categoryLabel(groupIndex)}\n'
                    '${rod.toY.toInt()} ${_seriesLabel(rodIndex)}',
                    ZTheme.mono(11, color: ZColors.ink),
                    textAlign: TextAlign.center,
                  ),
            ),
          ),
        ),
      );
    },
  );

  Widget _category(double value, double slot, bool rotate) {
    final index = value.round();
    final label = _categoryLabel(index);
    if (label.isEmpty) return const SizedBox.shrink();

    if (rotate) {
      // RotatedBox changes the layout box, so the width here becomes the space
      // the label occupies going up from the axis. Setting it from [slot] is
      // what keeps two neighbouring names from painting over each other.
      return RotatedBox(
        quarterTurns: 3,
        child: SizedBox(
          width: math.max(slot - 6, 40),
          child: Align(
            // Right in the unrotated box, which rotation puts nearest the axis:
            // names start at the baseline and read upward.
            alignment: Alignment.centerRight,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZTheme.mono(10),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: math.max(slot - 8, 24),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: ZTheme.mono(10),
      ),
    );
  }

  /// Bars fill their share of the group, capped so a report with only two
  /// series does not draw two slabs meeting at a seam, and floored so a bar is
  /// still visible when a report has a group per station or per route.
  double _rodWidth(double slot, int series) =>
      math.max(2, math.min(26, slot / series - 1));

  String _categoryLabel(int index) =>
      index < 0 || index >= chart.categories.length
      ? ''
      : chart.categories[index];

  String _seriesLabel(int index) =>
      index < 0 || index >= chart.series.length
      ? ''
      : chart.series[index].label;
}

class _PieChart extends StatelessWidget {
  const _PieChart(this.chart);

  final ChartView chart;

  @override
  Widget build(BuildContext context) {
    final slices = chart.slices;
    final total = slices.fold<double>(0, (sum, value) => sum + value);

    // Nothing to divide into parts. The page reports an empty run before
    // getting here, so this is a guard against a chart that would otherwise
    // paint zero-width sections and look like a rendering fault.
    if (slices.isEmpty || total <= 0) return const SizedBox.shrink();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 54,
        sections: [
          for (var i = 0; i < slices.length; i++)
            PieChartSectionData(
              value: slices[i],
              color: ZColors.series(i),
              radius: 118,
              // The legend already carries the names, so the slice carries the
              // number: together they say which status and how many.
              title: slices[i].toInt().toString(),
              titleStyle: ZTheme.mono(12, color: ZColors.bg),
              titlePositionPercentageOffset: .62,
            ),
        ],
      ),
    );
  }
}

/// Swatch beside its label, so a colour on the chart means a word on the page.
class ZChartLegend extends StatelessWidget {
  const ZChartLegend(this.chart, {super.key, this.spacing = 22});

  final ChartView chart;
  final double spacing;

  /// A bar chart's legend is its series; a pie's is its slices. Same list of
  /// colours, indexed the same way, which is why this needs no special case for
  /// which one the page drew.
  List<String> get _entries => chart.kind == ChartKind.bar
      ? [for (final series in chart.series) series.label]
      : chart.categories;

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    if (entries.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: spacing,
      runSpacing: 10,
      children: [
        for (var i = 0; i < entries.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: ZColors.series(i),
                  border: Border.all(
                    color: ZColors.line,
                    width: .5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(entries[i], style: const TextStyle(fontSize: 12)),
            ],
          ),
      ],
    );
  }
}

double _at(List<double> values, int index) =>
    index < 0 || index >= values.length ? 0 : values[index];
