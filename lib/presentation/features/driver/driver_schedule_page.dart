import 'package:flutter/material.dart';

import '../../shared/ui_table.dart';
import '../../shared/workflow_page.dart';
import '../booking/widgets/station_timetable.dart';

/// Supply only schedules assigned to the authenticated driver. Start/end/cancel
/// actions belong in each row; the presenter decides which are available.
class DriverSchedulePage extends StatelessWidget {
  const DriverSchedulePage({
    super.key,
    this.rows = const [],
    this.timetableRows = const [],
  });
  final List<UiTableRow> rows, timetableRows;
  @override
  Widget build(BuildContext context) => WorkflowPage(
    title: 'My driving schedule',
    section: 'DRIVER',
    children: [
      UiTable(
        columns: const ['Route', 'Schedule', 'Start time', 'Vehicle'],
        rows: rows,
        emptyLabel: 'No assigned schedules',
      ),
      StationTimetable(rows: timetableRows),
    ],
  );
}
