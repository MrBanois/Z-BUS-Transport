import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/ui_table.dart';
import '../../shared/workflow_page.dart';
import '../booking/widgets/station_timetable.dart';
import 'widgets/passenger_manifest.dart';

/// Pass the active trip's station times and manifest; availability of this page
/// is controlled by your navigation/presenter after a successful start command.
class CurrentTripPage extends StatelessWidget {
  const CurrentTripPage({
    super.key,
    this.timetableRows = const [],
    this.passengers = const [],
    this.onScan,
    this.onFinish,
  });
  final List<UiTableRow> timetableRows, passengers;
  final VoidCallback? onScan, onFinish;
  @override
  Widget build(BuildContext context) => WorkflowPage(
    title: 'Current trip',
    section: 'DRIVER',
    children: [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ZButton('Scan passenger QR', onPressed: onScan),
          ZButton('Finish trip', secondary: true, onPressed: onFinish),
        ],
      ),
      StationTimetable(rows: timetableRows),
      PassengerManifest(rows: passengers),
    ],
  );
}
