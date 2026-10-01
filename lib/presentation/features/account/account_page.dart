import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/ui_fields.dart';
import '../../shared/workflow_page.dart';

/// The presenter supplies account type and values. Employee department/position
/// remain read-only; persist edits through onSave and enforce permissions outside UI.
class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    this.isEmployee = false,
    this.values = const {},
    this.options = const {},
    this.errors = const {},
    this.onChanged,
    this.onSave,
  });
  final bool isEmployee;
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onSave;
  @override
  Widget build(BuildContext context) => WorkflowPage(
    title: 'My account',
    section: 'USER',
    children: [
      ZPanel(
        child: UiFields(
          fields: [
            const UiFieldSpec('id', 'ID', readOnly: true),
            const UiFieldSpec('firstName', 'First name'),
            const UiFieldSpec('lastName', 'Last name'),
            UiFieldSpec(
              'department',
              'Department',
              kind: UiFieldKind.select,
              readOnly: isEmployee,
            ),
            UiFieldSpec(
              'position',
              'Position',
              kind: UiFieldKind.select,
              readOnly: isEmployee,
            ),
          ],
          values: values,
          options: options,
          errors: errors,
          onChanged: onChanged,
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: ZButton('Save profile', onPressed: onSave),
      ),
    ],
  );
}
