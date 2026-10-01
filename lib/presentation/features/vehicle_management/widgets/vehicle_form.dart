import 'package:flutter/material.dart';

import '../../../shared/crud_form.dart';
import '../../../shared/ui_fields.dart';

/// Supply generated IDs as read-only values. Persist via onSave in your presenter.
class VehicleForm extends StatelessWidget {
  const VehicleForm({
    super.key,
    this.values = const {},
    this.options = const {},
    this.errors = const {},
    this.onChanged,
    this.onSave,
    this.onDelete,
    this.extra,
  });
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onSave, onDelete;
  final Widget? extra;
  @override
  Widget build(BuildContext context) => CrudForm(
    title: 'Vehicle',
    fields: const [
      UiFieldSpec('id', 'ID', readOnly: true, hint: 'Assigned automatically'),
      UiFieldSpec('plate', 'Plate'),
      UiFieldSpec('seats', 'Seats', kind: UiFieldKind.number),
      UiFieldSpec('type', 'Type', kind: UiFieldKind.select),
      UiFieldSpec('active', 'Active', kind: UiFieldKind.toggle),
    ],
    values: values,
    options: options,
    errors: errors,
    onChanged: onChanged,
    onSave: onSave,
    onDelete: onDelete,
    extra: extra,
  );
}
