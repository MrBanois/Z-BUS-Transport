import 'package:flutter/material.dart';

import '../../../shared/design_system.dart';
import '../../../shared/ui_fields.dart';

/// Supply selected route options and draft values. Validate capacity and add the
/// draft to your cart through onAdd; this component never allocates seats itself.
class SeatSelection extends StatelessWidget {
  const SeatSelection({
    super.key,
    this.values = const {},
    this.options = const {},
    this.errors = const {},
    this.onChanged,
    this.onAdd,
  });
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) => ZPanel(
    child: Column(
      children: [
        UiFields(
          fields: const [
            UiFieldSpec('pickup', 'Pickup station', kind: UiFieldKind.select),
            UiFieldSpec(
              'dropOff',
              'Drop-off station',
              kind: UiFieldKind.select,
            ),
            UiFieldSpec('seats', 'Seats to reserve', kind: UiFieldKind.number),
          ],
          values: values,
          options: options,
          errors: errors,
          onChanged: onChanged,
        ),
        ZButton('Add trip', onPressed: onAdd),
      ],
    ),
  );
}
