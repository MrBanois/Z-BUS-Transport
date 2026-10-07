import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../data/report_export.dart';
import '../presentation/features/reports/reports_page.dart';
import '../presentation/shared/report_view.dart';
import 'reports_controller.dart';

/// PNG bytes for whatever [boundary] has painted, at a resolution that keeps
/// text readable when the picture is opened full size.
///
/// Null rather than a thrown error when there is nothing to capture: the chart
/// has not been laid out yet, and "nothing to export" is a better answer than a
/// stack trace reaching the user.
Future<Uint8List?> capturePng(
  RenderRepaintBoundary boundary, {
  double pixelRatio = 3,
}) async {
  try {
    if (!boundary.attached) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) return null;
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } catch (_) {
    return null;
  }
}

/// The statistic reports screen's data and side effects.
///
/// This is where a report becomes a file. The controller knows what the report
/// said and the page knows where to put it; only here do those two meet, along
/// with the two things a screen cannot do for itself — hold the widget to
/// capture and write bytes to disk.
class ReportsHost extends StatefulWidget {
  const ReportsHost({
    super.key,
    required this.controller,
    this.writer = const FileSaverReportWriter(),
  });

  final ReportsController controller;

  /// Swapped for a fake in tests, which is the only way to assert what an
  /// export contained without a save dialog in the way.
  final ReportFileWriter writer;

  @override
  State<ReportsHost> createState() => _ReportsHostState();
}

class _ReportsHostState extends State<ReportsHost> {
  ReportsController get _c => widget.controller;

  /// Owned here rather than in the page: the page only attaches it to a
  /// `RepaintBoundary`, and reading it back is this layer's business.
  ///
  /// Typed as a bare [GlobalKey]: the capture boundary is a `RepaintBoundary`,
  /// a `StatelessWidget`, which `GlobalKey<T>`'s `T extends State` bound
  /// excludes. The key's job here is to turn into a `RenderObject` to paint,
  /// and an untyped key does that.
  final GlobalKey capture = GlobalKey();

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChanged);
    // Scheduled, never called from build: the controller's first
    // notifyListeners would arrive while this widget is building, which throws.
    _afterFrame(_c.run);
  }

  @override
  void didUpdateWidget(covariant ReportsHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onChanged);
    _c.addListener(_onChanged);
    _afterFrame(_c.run);
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _afterFrame(Future<void> Function() work) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) work();
    });
  }

  /// `zbus-station-usage-2026-10-07`, so two exports of the same report on
  /// different days do not quietly overwrite one another.
  String _stem() {
    final now = DateTime.now();
    final day =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return 'zbus-${_c.spec.fileSlug}-$day';
  }

  Future<void> _exportPicture() async {
    final attached = capture.currentContext?.findRenderObject();
    if (attached is! RenderRepaintBoundary) {
      _c.announceFailure('There is no chart to export yet. Run the report first.');
      return;
    }
    final bytes = await capturePng(attached);
    if (bytes == null) {
      _c.announceFailure('The chart could not be captured. Run the report first.');
      return;
    }
    final name = _stem();
    try {
      await widget.writer.picture(name, bytes);
      _c.announce('Saved $name.png');
    } catch (_) {
      _c.announceFailure('The picture could not be saved.');
    }
  }

  Future<void> _exportSpreadsheet() async {
    final view = _c.view;
    if (view == null) {
      _c.announceFailure('There is no table to export yet. Run the report first.');
      return;
    }
    final name = _stem();
    try {
      final bytes = ReportSpreadsheet.build(
        title: _c.spec.name,
        dateRange: view.dateRange,
        columns: view.columns,
        rows: view.rows,
      );
      await widget.writer.spreadsheet(name, bytes);
      _c.announce('Saved $name.xlsx');
    } catch (_) {
      _c.announceFailure('The spreadsheet could not be written.');
    }
  }

  @override
  Widget build(BuildContext context) => ReportsPage(
    reports: [for (final spec in _c.reports) ReportChoice(spec.id, spec.name)],
    selectedId: _c.spec.id,
    summary: _c.spec.summary,
    fields: _c.spec.fields,
    values: _c.values,
    errors: _c.errors,
    view: _c.view,
    chartIndex: _c.chartIndex,
    loading: _c.loading,
    error: _c.error,
    notice: _c.notice,
    captureKey: capture,
    onSelect: _c.select,
    onChanged: _c.set,
    onRun: _c.run,
    onChart: _c.showChart,
    onExportPicture: _exportPicture,
    onExportSpreadsheet: _exportSpreadsheet,
    onDismiss: _c.dismiss,
  );
}
