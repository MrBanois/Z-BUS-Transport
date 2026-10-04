import 'package:flutter/material.dart';

import '../../../shared/crud_form.dart';
import '../../../shared/ui_fields.dart';

/// Supply generated IDs as read-only values. Persist via onSave in your presenter.
class UserForm extends StatelessWidget {
  const UserForm({
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
    title: 'User',
    fields: const [
      UiFieldSpec('id', 'ID', readOnly: true, hint: 'Assigned automatically'),
      UiFieldSpec('firstName', 'First name'),
      UiFieldSpec('lastName', 'Last name'),
      UiFieldSpec('email', 'Email'),
      UiFieldSpec('department', 'Department', kind: UiFieldKind.select),
      UiFieldSpec('position', 'Position', kind: UiFieldKind.select),
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
