import 'package:flutter/material.dart';

import '../../../shared/ui_table.dart';

/// Feed precomputed station arrival times from a presenter. Reuse this widget in
/// schedule management, booking and driver screens to keep their layout identical.
class StationTimetable extends StatelessWidget {
  const StationTimetable({super.key, this.rows = const []});
  final List<UiTableRow> rows;
  @override
  Widget build(BuildContext context) => UiTable(
    columns: const ['Station order', 'Station', 'Time'],
    rows: rows,
    showActions: false,
    emptyLabel: 'No station timetable',
  );
}
