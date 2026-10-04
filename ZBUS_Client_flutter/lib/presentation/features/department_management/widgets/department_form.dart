import 'package:flutter/material.dart';

import '../../../shared/crud_form.dart';
import '../../../shared/ui_fields.dart';

/// The employee switch reports account type; derive its ID prefix outside UI.
/// Supply generated IDs as read-only values. Persist via onSave in your presenter.
class DepartmentForm extends StatelessWidget {
  const DepartmentForm({
    super.key,
    this.values = const {},
    this.options = const {},
    this.errors = const {},
    this.onChanged,
    this.onSave,
    this.onDelete,
    this.extra,
    this.bare = false,
  });
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onSave, onDelete;
  final Widget? extra;

  /// Render only the fields; the host supplies the dialog shell.
  final bool bare;
  @override
  Widget build(BuildContext context) => CrudForm(
    title: 'Department',
    fields: const [
      UiFieldSpec('id', 'ID', readOnly: true, hint: 'Assigned automatically'),
      UiFieldSpec('employee', 'Employee department', kind: UiFieldKind.toggle),
      UiFieldSpec('name', 'Name'),
    ],
    values: values,
    options: options,
    errors: errors,
    onChanged: onChanged,
    onSave: onSave,
    onDelete: onDelete,
    extra: extra,
    bare: bare,
  );
}
