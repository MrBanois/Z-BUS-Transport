import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/ui_table.dart';
import '../../shared/workflow_page.dart';

/// Supply aggregated values from the trip-log use case. No totals are calculated
/// here: seats booked and actual passengers boarded are distinct report metrics.
class TripSummary extends StatelessWidget {
  const TripSummary({
    super.key,
    this.seatsBooked,
    this.passengersBoarded,
    this.noShows,
    this.rows = const [],
    this.onBack,
  });
  final String? seatsBooked, passengersBoarded, noShows;
  final List<UiTableRow> rows;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => WorkflowPage(
    title: 'Trip summary',
    section: 'DRIVER',
    children: [
      Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          Text('Seats booked: ${seatsBooked ?? '—'}'),
          Text('Passengers boarded: ${passengersBoarded ?? '—'}'),
          Text('No-shows: ${noShows ?? '—'}'),
        ],
      ),
      UiTable(
        columns: const [
          'Booking',
          'Pickup',
          'Drop-off',
          'Passengers boarded',
          'Status',
        ],
        rows: rows,
        showActions: false,
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: ZButton('Back to my schedule', onPressed: onBack),
      ),
    ],
  );
}
