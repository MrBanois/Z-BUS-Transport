import 'package:flutter/material.dart';

import '../../../shared/ui_table.dart';

/// Map booking details into rows. Keep reserved seats and actual boarded people
/// separate. Row actions should delegate check-in/no-show commands to a use case.
class PassengerManifest extends StatelessWidget {
  const PassengerManifest({super.key, this.rows = const []});
  final List<UiTableRow> rows;
  @override
  Widget build(BuildContext context) => UiTable(
    columns: const [
      'Booking',
      'Trip',
      'Passenger',
      'Pickup',
      'Drop-off',
      'Seats booked',
      'Passengers boarded',
      'Status',
    ],
    rows: rows,
    emptyLabel: 'No passenger bookings',
  );
}
