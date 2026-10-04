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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ZPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ZLabel('BOOKING / $bookingId', color: ZColors.accent),
              Text(bookedAt, style: ZTheme.mono(10)),
            ],
          ),
          const ZGap(20),
          Text(bookingId, style: ZTheme.display(36)),
          if (onCancelAll != null) ...[
            const ZGap(20),
            Align(
              alignment: Alignment.centerLeft,
              child: ZButton(
                'Cancel all',
                secondary: true,
                onPressed: onCancelAll,
              ),
            ),
          ],
          for (var i = 0; i < trips.length; i++) ...[
            const ZGap(22),
            const ZRule(),
            const ZGap(18),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ZLabel(
                  'TRIP ${trips[i].number}',
                  color: ZColors.accent,
                ),
                ZStatus(trips[i].status),
              ],
            ),
            const ZGap(15),
            Text(
              '${trips[i].route} / ${trips[i].schedule}',
              style: ZTheme.display(27),
            ),
            const ZGap(15),
            ZKeyValue('JOURNEY', '${trips[i].pickup} → ${trips[i].dropOff}'),
            const ZGap(20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ZButton('See QR', onPressed: trips[i].onQr),
                if (trips[i].onCancel != null)
                  ZButton(
                    'Cancel trip',
                    secondary: true,
                    onPressed: trips[i].onCancel,
                  ),
              ],
            ),
          ],
        ],
      ),
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
  Widget build(BuildContext context) => ZDialog(
    title: bookingDetail,
    width: 320,
    actions: [
      ZButton(
        'Close',
        secondary: true,
        onPressed: () => Navigator.pop(context),
      ),
    ],
    child: Center(child: qr),
  );
}