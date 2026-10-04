import 'package:flutter/material.dart';

import '../../../shared/account_copy.dart';
import '../../../shared/crud_form.dart';
import '../../../shared/ui_fields.dart';

/// Create or edit a staff account.
///
/// Same fields as [UserForm] less the account type, and that omission is the whole
/// difference between the two screens. Every account reachable from here is staff,
/// so a switch offering to make one a passenger would contradict the screen's own
/// title and could only ever be turned off.
///
/// ISEMP is still written on every save, because `PUT /api/user/{id}` replaces the
/// whole row: the controller supplies it from the screen's own default rather than
/// from a control that does not exist. Dropping the column from the body would
/// turn saving from this screen into a way to demote the account.
class EmployeeForm extends StatelessWidget {
  const EmployeeForm({
    super.key,
    this.values = const {},
    this.options = const {},
    this.errors = const {},
    this.onChanged,
    this.onSave,
    this.onDelete,
    this.extra,
    this.bare = false,
    this.lockPassword = false,
  });
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onSave, onDelete;
  final Widget? extra;

  /// Render only the fields; the host supplies the dialog shell.
  final bool bare;

  /// See [UserForm.lockPassword].
  final bool lockPassword;
  @override
  Widget build(BuildContext context) => CrudForm(
    title: 'Employee',
    fields: [
      const UiFieldSpec(
        'id',
        'ID',
        readOnly: true,
        hint: 'Assigned automatically',
      ),
      const UiFieldSpec('firstName', 'First name'),
      const UiFieldSpec('lastName', 'Last name'),
      const UiFieldSpec('email', 'Email'),
      const UiFieldSpec('department', 'Department', kind: UiFieldKind.select),
      const UiFieldSpec('position', 'Position', kind: UiFieldKind.select),
      const UiFieldSpec('salary', 'Salary', kind: UiFieldKind.number),
      UiFieldSpec(
        'password',
        'Password',
        kind: UiFieldKind.password,
        hint: lockPassword ? kNewPasswordHint : kPasswordKeptHint,
      ),
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