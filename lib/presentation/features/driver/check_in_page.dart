import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
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
    title: 'Scan. Verify.\nLet them ride.',
    section: 'DRIVER',
    children: [
      ZPanel(
        child:
            scannerPreview ??
            const SizedBox(
              height: 180,
              child: Center(child: Icon(Icons.qr_code_scanner, size: 72)),
            ),
      ),
      UiFields(
        fields: const [UiFieldSpec('token', 'QR token')],
        values: values,
        onChanged: onChanged,
        errors: errors,
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: ZButton('Verify token', onPressed: onVerify),
      ),
      ZPanel(
        child: UiFields(
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
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: ZButton('Confirm boarding', onPressed: onConfirm),
      ),
    ],
  );
}
