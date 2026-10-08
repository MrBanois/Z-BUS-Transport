import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/page_copy.dart';
import '../../shared/report_chart.dart';
import '../../shared/report_table.dart';
import '../../shared/report_view.dart';
import '../../shared/ui_fields.dart';
import '../../shared/workflow_page.dart';

/// The statistic reports screen: one of five reports, its own parameters, the
/// chart it draws, and the table underneath with an export for each.
///
/// Everything it shows arrives as data and everything it does is a callback.
/// Which columns become bars, which stay in the table alone and which report
/// offers a second view are decided upstream; this file lays the outcome out
/// and knows nothing about endpoints, dates or bookings.
class ReportsPage extends StatelessWidget {
  const ReportsPage({
    super.key,
    this.reports = const [],
    this.selectedId = '',
    this.summary = '',
    this.fields = const [],
    this.values = const {},
    this.errors = const {},
    this.view,
    this.chartIndex = 0,
    this.loading = false,
    this.error,
    this.notice,
    this.captureKey,
    this.onSelect,
    this.onChanged,
    this.onRun,
    this.onChart,
    this.onExportPicture,
    this.onExportSpreadsheet,
    this.onDismiss,
  });

  /// The picker's entries, in order.
  final List<ReportChoice> reports;
  final String selectedId;

  /// One line about what the selected report answers.
  final String summary;

  /// The selected report's own inputs — a year, or a date range.
  final List<UiFieldSpec> fields;
  final Map<String, Object?> values;
  final Map<String, String> errors;

  /// The last completed run, or null before the first.
  final ReportView? view;
  final int chartIndex;
  final bool loading;

  final String? error;
  final String? notice;

  /// Marks the block the picture export captures. Owned by the host, which is
  /// also the thing that reads it back. Null when there is no host (a layout
  /// preview), in which case the boundary is simply omitted.
  final GlobalKey? captureKey;

  final ValueChanged<String>? onSelect;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onRun;
  final ValueChanged<int>? onChart;
  final VoidCallback? onExportPicture, onExportSpreadsheet, onDismiss;

  String get _selectedName {
    for (final choice in reports) {
      if (choice.id == selectedId) return choice.name;
    }
    return reports.isEmpty ? '' : reports.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final result = view;
    final plotted = result != null && result.rows.isNotEmpty;

    return WorkflowPage(
      title: analyticsReports.headline,
      section: 'STATISTIC',
      index: analyticsReports.index,
      kicker: analyticsReports.kicker,
      description: analyticsReports.standfirst,
      action: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        children: [
          // Disabled rather than hidden when there is nothing to export. A
          // button that vanishes leaves the reader wondering where export went;
          // a greyed one says it needs a report first.
          ZButton(
            'Export picture',
            icon: Icons.image_outlined,
            secondary: true,
            onPressed: result == null ? null : onExportPicture,
          ),
          ZButton(
            'Export Excel',
            icon: Icons.table_view_outlined,
            secondary: true,
            onPressed: result == null ? null : onExportSpreadsheet,
          ),
        ],
      ),
      children: [
        ZSectionTitle('01 / SELECTION', 'Choose a report'),
        ZPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final choice in reports)
                    ZButton(
                      choice.name,
                      compact: true,
                      // The chosen one is the filled button, so the selection
                      // is readable without a separate highlight.
                      secondary: choice.id != selectedId,
                      onPressed: onSelect == null
                          ? null
                          : () => onSelect!(choice.id),
                    ),
                ],
              ),
              const ZGap(18),
              Text(
                summary,
                style: const TextStyle(
                  color: ZColors.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        ZSectionTitle('02 / PARAMETERS', 'Set the parameters'),
        ZPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // One field per cell rather than one per row: a year on its own
              // would stretch an input the width of the page, and a range reads
              // as a pair.
              ZColumns(
                desktopColumns: fields.length.clamp(1, 3),
                children: [
                  for (final field in fields)
                    UiFields(
                      fields: [field],
                      values: values,
                      errors: errors,
                      onChanged: onChanged,
                    ),
                ],
              ),
              const ZGap(22),
              ZButton(
                loading ? 'Running' : 'Run report',
                icon: loading ? null : Icons.play_arrow,
                onPressed: loading ? null : onRun,
              ),
            ],
          ),
        ),
        if (error != null) ...[
          ZNotice(
            'Could not generate the report',
            error!,
            color: ZColors.accent,
            icon: Icons.error_outline,
          ),
          const ZGap(4),
          Align(
            alignment: Alignment.centerLeft,
            child: ZButton(
              'Dismiss',
              secondary: true,
              compact: true,
              onPressed: onDismiss,
            ),
          ),
        ],
        if (notice != null) ...[
          ZNotice(
            'Export',
            notice!,
            color: ZColors.success,
            icon: Icons.check_circle_outline,
          ),
          const ZGap(4),
          Align(
            alignment: Alignment.centerLeft,
            child: ZButton(
              'Dismiss',
              secondary: true,
              compact: true,
              onPressed: onDismiss,
            ),
          ),
        ],
        if (plotted) ...[
          ZSectionTitle('03 / CHART', _selectedName),
          _chart(result),
          ZSectionTitle('04 / TABLE', _selectedName),
          ZPanel(
            child: ZReportTable(columns: result.columns, rows: result.rows),
          ),
        ] else ...[
          ZSectionTitle('03 / RESULTS', _selectedName),
          _awaiting(result),
        ],
      ],
    );
  }

  /// What the results area says before there are any.
  ///
  /// Three different situations and three different answers, because "no
  /// results" means something different each time: not yet asked, asked and
  /// refused, asked and found nothing. Only the last is the report's fault.
  Widget _awaiting(ReportView? result) {
    if (result != null) {
      return const ZEmpty(
        'No records',
        'That range produced no rows, so there is nothing to chart or list.',
      );
    }
    if (loading) {
      return const ZEmpty('Loading', 'Fetching the report from the server.');
    }
    return ZEmpty(
      'Nothing run yet',
      error ?? 'Choose a report, set its parameters, then run it.',
    );
  }

  /// The chart, with the switch outside the captured area so a picture shows
  /// the report rather than the control used to pick it.
  ///
  /// The chart block itself scrolls as one unit: the boundary sits *inside* the
  /// scroll, wrapping the full-width panel, so a capture records every group at
  /// its natural width instead of the slice the viewport happened to show. A
  /// pie never overflows, so it gets no scroll — just the boundary.
  Widget _chart(ReportView result) {
    final chart = result.chartAt(chartIndex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (result.charts.length > 1) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < result.charts.length; i++)
                ZButton(
                  result.charts[i].label,
                  compact: true,
                  secondary: i != chartIndex,
                  onPressed: onChart == null ? null : () => onChart!(i),
                ),
            ],
          ),
          const ZGap(18),
        ],
        if (chart.kind == ChartKind.pie)
          _boundary(child: ZPanel(child: _block(result, chart)))
        else
          LayoutBuilder(
            builder: (context, constraints) => ZHScroll(
              child: _boundary(
                // 48 is the panel's own 24-per-side padding, so the chart's
                // natural width is never clipped by the panel that carries it.
                child: SizedBox(
                  width: math.max(
                    constraints.maxWidth,
                    ZReportChart.naturalWidth(chart) + 48,
                  ),
                  child: ZPanel(child: _block(result, chart)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// What the chart panel carries: the report's name, the range it covered,
  /// the chart and the legend that decodes its colours.
  Widget _block(ReportView result, ChartView chart) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        _selectedName.toUpperCase(),
        style: ZTheme.mono(15, color: ZColors.ink),
      ),
      if (result.dateRange.isNotEmpty) ...[
        const SizedBox(height: 7),
        ZLabel(result.dateRange, color: ZColors.muted),
      ],
      const ZGap(24),
      ZReportChart(chart),
      const ZGap(24),
      ZChartLegend(chart),
    ],
  );

  /// Wrap in the capture boundary when the host provided one; a preview has no
  /// host and therefore nothing to capture.
  Widget _boundary({required Widget child}) => captureKey == null
      ? child
      : RepaintBoundary(key: captureKey, child: child);
}
