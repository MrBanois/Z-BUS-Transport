import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/page_copy.dart';
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
    title: driverActiveTrip.headline,
    section: 'DRIVER',
    index: driverActiveTrip.index,
    kicker: driverActiveTrip.kicker,
    description: driverActiveTrip.standfirst,
    action: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ZButton(
          'Scan passenger QR',
          onPressed: onScan,
          icon: Icons.qr_code_scanner,
        ),
        ZButton('Finish trip', secondary: true, onPressed: onFinish),
      ],
    ),
    children: [
      ZSectionTitle('01 / TIMETABLE', 'Stops and arrival times'),
      StationTimetable(rows: timetableRows),
      const ZGap(26),
      ZSectionTitle('02 / MANIFEST', 'Passengers on this run'),
      PassengerManifest(rows: passengers),
    ],
  );
}