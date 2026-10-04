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
    title: 'RUN\nCOMPLETE.',
    section: 'DRIVER',
    index: '16 / DRIVER',
    kicker: 'DRIVER / COMPLETED TRIP',
    description:
        'Closed runs for the authenticated driver. Booked and boarded counts '
        'are reported separately and never reconciled in the UI.',
    children: [
      ZColumns(
        children: [
          ZStat(
            'Seats booked',
            seatsBooked ?? '—',
            'Reserved capacity on this run',
          ),
          ZStat(
            'Passengers boarded',
            passengersBoarded ?? '—',
            'Confirmed at the boarding stop',
          ),
          ZStat('No-shows', noShows ?? '—', 'Reserved but never boarded'),
        ],
      ),
      const ZGap(34),
      ZSectionTitle('01 / DETAIL', 'Bookings on this run'),
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
      const ZGap(20),
      ZButton(
        'Back to my schedule',
        secondary: true,
        onPressed: onBack,
        icon: Icons.arrow_back,
      ),
    ],
  );
}