import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/page_copy.dart';
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
    title: driverSchedule.headline,
    section: 'DRIVER',
    index: driverSchedule.index,
    kicker: driverSchedule.kicker,
    description: driverSchedule.standfirst,
    children: [
      ZSectionTitle(
        '01 / ASSIGNED',
        rows.isEmpty ? 'No assigned schedules' : 'Your runs',
      ),
      UiTable(
        columns: const ['Route', 'Schedule', 'Start time', 'Vehicle'],
        rows: rows,
        emptyLabel: 'No assigned schedules',
      ),
      if (timetableRows.isNotEmpty) ...[
        const ZGap(26),
        ZSectionTitle('02 / TIMETABLE', 'Stops and arrival times'),
        StationTimetable(rows: timetableRows),
      ],
    ],
  );
}