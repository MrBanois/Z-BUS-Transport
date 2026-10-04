import 'package:flutter/material.dart';

import '../../../shared/account_copy.dart';
import '../../../shared/crud_form.dart';
import '../../../shared/ui_fields.dart';

/// Create or edit an account.
///
/// The fields mirror the write body exactly, and they have to: `PUT /api/user/{id}`
/// replaces the whole row, so a form that omitted salary or the account type would
/// silently reset them on every rename. That is why the account type is offered
/// here rather than only on [EmployeeForm].
///
/// What the account type changes, it changes in the field specs rather than in a
/// rebuild: a passenger's salary is not something an administrator sets, and a
/// passenger can only be assigned to passenger-facing departments and positions,
/// because the server refuses any other combination. Locking salary is exact — it
/// is zeroed in the draft by the controller, so the value on screen is the value
/// saved. Narrowing the two dropdowns is the closest honest equivalent for
/// them: hard-disabling them would leave no way to give a passenger a
/// department at all, which is the opposite of what this screen is for.
///
/// [values] may carry `id` to show an existing account's id read-only. Leaving it
/// out is what makes the dialog a create, because the server generates the id.
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

  /// The password is required to create an account and optional to edit one, so
  /// the host, which knows which this is, says which rather than the form
  /// guessing from an empty draft.
  final bool lockPassword;
  @override
  Widget build(BuildContext context) {
    final staff = values['employee'] != false;
    return CrudForm(
      title: 'User',
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
        UiFieldSpec(
          'salary',
          'Salary',
          kind: UiFieldKind.number,
          readOnly: !staff,
          help: staff ? null : 'Passenger accounts are not paid',
        ),
        const UiFieldSpec('employee', 'Staff account', kind: UiFieldKind.toggle),
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
}