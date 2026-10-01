import 'package:flutter/material.dart';

import '../../../shared/design_system.dart';

/// Display data only. Provide cancel callbacks only when your booking use case
/// allows cancellation; absence of a callback hides the corresponding button.
class BookedTripView {
  const BookedTripView({
    required this.number,
    required this.route,
    required this.schedule,
    required this.pickup,
    required this.dropOff,
    required this.status,
    this.onQr,
    this.onCancel,
  });
  final String number, route, schedule, pickup, dropOff, status;
  final VoidCallback? onQr, onCancel;
}

class BookingGroupCard extends StatelessWidget {
  const BookingGroupCard({
    super.key,
    required this.bookingId,
    required this.bookedAt,
    this.trips = const [],
    this.onCancelAll,
  });
  final String bookingId, bookedAt;
  final List<BookedTripView> trips;
  final VoidCallback? onCancelAll;
  @override
  Widget build(BuildContext context) => ZPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(bookingId, style: Theme.of(context).textTheme.titleLarge),
        Text(bookedAt),
        if (onCancelAll != null)
          Align(
            alignment: Alignment.centerLeft,
            child: ZButton(
              'Cancel all',
              secondary: true,
              onPressed: onCancelAll,
            ),
          ),
        for (final trip in trips)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ZRule(),
                const SizedBox(height: 12),
                Text('Trip ${trip.number} / ${trip.route} / ${trip.schedule}'),
                Text('${trip.pickup} → ${trip.dropOff}'),
                ZStatus(trip.status),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ZButton('See QR', onPressed: trip.onQr),
                    if (trip.onCancel != null)
                      ZButton(
                        'Cancel trip',
                        secondary: true,
                        onPressed: trip.onCancel,
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Inject a real QR widget from your integration. Never synthesize fake QR codes.
class BookingQrDialog extends StatelessWidget {
  const BookingQrDialog({
    super.key,
    required this.bookingDetail,
    required this.qr,
  });
  final String bookingDetail;
  final Widget qr;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(bookingDetail),
    content: SizedBox(width: 280, child: qr),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}
