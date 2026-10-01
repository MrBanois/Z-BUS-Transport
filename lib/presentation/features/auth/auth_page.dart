import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/ui_fields.dart';
import '../../shared/workflow_page.dart';

/// Connect submit to your authentication use case. Public registration should
/// create a passenger on the server. No demo email or password bypass exists.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    this.register = false,
    this.values = const {},
    this.options = const {},
    this.errors = const {},
    this.onChanged,
    this.onSubmit,
  });
  final bool register;
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onSubmit;
  @override
  Widget build(BuildContext context) => WorkflowPage(
    title: register ? 'Create account' : 'Welcome aboard',
    section: 'USER',
    children: [
      ZPanel(
        child: UiFields(
          fields: [
            const UiFieldSpec('email', 'Email'),
            const UiFieldSpec(
              'password',
              'Password',
              kind: UiFieldKind.password,
            ),
            if (register) ...[
              const UiFieldSpec('firstName', 'First name'),
              const UiFieldSpec('lastName', 'Last name'),
              const UiFieldSpec(
                'department',
                'Department',
                kind: UiFieldKind.select,
              ),
              const UiFieldSpec(
                'position',
                'Position',
                kind: UiFieldKind.select,
              ),
            ],
          ],
          values: values,
          options: options,
          errors: errors,
          onChanged: onChanged,
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: ZButton(register ? 'Register' : 'Login', onPressed: onSubmit),
      ),
    ],
  );
}
