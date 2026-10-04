import 'package:flutter/material.dart';

import '../../../shared/crud_form.dart';
import '../../../shared/ui_fields.dart';
import 'permission_editor.dart';

/// The employee switch reports account type; derive its ID prefix outside UI.
/// Supply generated IDs as read-only values. Persist via onSave in your presenter.
///
/// The `employee` toggle is the UI face of `POSITION.ISEMP`: when it reports
/// false, the server only offers this position to self-registration
/// (`GET /api/position/passenger`). Keeping the mapping here would duplicate the
/// rule, so the presenter decides and the toggle only reports.
class PositionForm extends StatelessWidget {
  const PositionForm({
    super.key,
    this.values = const {},
    this.options = const {},
    this.errors = const {},
    this.permissionMask,
    this.onPermissionChanged,
    this.onChanged,
    this.onSave,
    this.onDelete,
    this.extra,
  });
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;

  /// Raw `POSITION.PERMISSION` mask, decoded by [PermissionEditor].
  final String? permissionMask;

  /// Reports one screen toggled; the presenter re-encodes and persists.
  final void Function(String, bool)? onPermissionChanged;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onSave, onDelete;
  final Widget? extra;
  @override
  Widget build(BuildContext context) => CrudForm(
    title: 'Position',
    fields: const [
      UiFieldSpec('id', 'ID', readOnly: true, hint: 'Assigned automatically'),
      UiFieldSpec('employee', 'Employee position', kind: UiFieldKind.toggle),
      UiFieldSpec('name', 'Name'),
    ],
    values: values,
    options: options,
    errors: errors,
    onChanged: onChanged,
    onSave: onSave,
    onDelete: onDelete,
    extra:
        extra ??
        PermissionEditor(
          mask: permissionMask,
          onChanged: onPermissionChanged,
        ),
  );
}
