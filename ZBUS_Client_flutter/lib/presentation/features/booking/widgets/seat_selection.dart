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
    this.maxSeats = 4,
  });
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onAdd;
  final int maxSeats;
  @override
  Widget build(BuildContext context) {
    final seats = int.tryParse(values['seats']?.toString() ?? '') ?? 1;
    return ZPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ZLabel('SEATS / JOURNEY', color: ZColors.accent),
          const ZGap(22),
          ZColumns(
            desktopColumns: 2,
            children: [
              UiFields(
                fields: const [
                  UiFieldSpec(
                    'pickup',
                    'Board at',
                    kind: UiFieldKind.select,
                  ),
                  UiFieldSpec(
                    'dropOff',
                    'Get off at',
                    kind: UiFieldKind.select,
                  ),
                ],
                values: values,
                options: options,
                errors: errors,
                onChanged: onChanged,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ZLabel('Seats to reserve'),
                  const ZGap(14),
                  ZStepper(
                    value: seats,
                    min: 1,
                    max: maxSeats,
                    onChanged: onChanged == null
                        ? null
                        : (next) => onChanged!('seats', '$next'),
                    hint: 'Maximum $maxSeats seats per reservation.',
                  ),
                ],
              ),
            ],
          ),
          const ZGap(6),
          Align(
            alignment: Alignment.centerLeft,
            child: ZButton('Add trip', onPressed: onAdd),
          ),
        ],
      ),
    );
  }
}