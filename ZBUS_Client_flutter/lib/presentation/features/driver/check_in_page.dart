import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/page_copy.dart';
import '../../shared/ui_fields.dart';
import '../../shared/workflow_page.dart';

/// Provide a real scanner as scannerPreview and pass decoded tokens to your
/// presenter. After verification, populate pickup/dropOff/seats from the booking.
/// Validate and persist passengersBoarded separately from reserved seats in the
/// application layer (TRIP_LOG_DETAIL.PASSENGER); no check-in state is stored here.
class CheckInPage extends StatelessWidget {
  const CheckInPage({
    super.key,
    this.values = const {},
    this.errors = const {},
    this.onChanged,
    this.onVerify,
    this.onConfirm,
    this.scannerPreview,
  });
  final Map<String, Object?> values;
  final Map<String, String> errors;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onVerify, onConfirm;
  final Widget? scannerPreview;
  @override
  Widget build(BuildContext context) => WorkflowPage(
    title: driverCheckIn.headline,
    section: 'DRIVER',
    index: driverCheckIn.index,
    kicker: driverCheckIn.kicker,
    description: driverCheckIn.standfirst,
    children: [
      ZPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZLabel('01 / SCANNER', color: ZColors.accent),
            const ZGap(22),
            Container(
              width: double.infinity,
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ZColors.surface2,
                border: Border.all(color: ZColors.line),
              ),
              child:
                  scannerPreview ??
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 72,
                    color: ZColors.muted,
                  ),
            ),
            const ZGap(22),
            UiFields(
              fields: const [UiFieldSpec('token', 'QR token')],
              values: values,
              onChanged: onChanged,
              errors: errors,
            ),
            const ZGap(2),
            ZButton(
              'Verify token',
              onPressed: onVerify,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
      const ZGap(4),
      ZPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZLabel('02 / BOARDING', color: ZColors.accent),
            const ZGap(22),
            UiFields(
              fields: const [
                UiFieldSpec('pickup', 'Pickup', readOnly: true),
                UiFieldSpec('dropOff', 'Drop-off', readOnly: true),
                UiFieldSpec('seats', 'Seats booked', readOnly: true),
                UiFieldSpec(
                  'passengersBoarded',
                  'Passengers boarding',
                  kind: UiFieldKind.number,
                ),
              ],
              values: values,
              errors: errors,
              onChanged: onChanged,
            ),
            const ZRule(),
            const ZGap(22),
            const ZNotice(
              'Reserved is not boarded',
              'Seats booked come from the reservation. Passengers boarding is '
              'what you confirm at this stop; the two are stored separately.',
            ),
            const ZGap(22),
            ZButton(
              'Confirm boarding',
              onPressed: onConfirm,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    ],
  );
}