import 'package:flutter/material.dart';

import 'design_system.dart';
import 'ui_fields.dart';

/// Reusable create/edit form. The parent owns the draft, validation, generated
/// ID and save/delete use cases. Rebuild with errors on a failed submission.
///
/// By default this draws the whole squared [ZDialog] shell, so a feature form can
/// be shown with `showDialog` and nothing else. Pass [bare] when the caller needs
/// to supply that shell itself — the management hosts do, because they have to
/// disable Save while a request is in flight and add a notice the shared shell
/// has no slot for, and neither is possible once [ZDialog] has been built.
///
/// Using the squared [ZDialog] keeps create/edit flows matching the rest of the
/// design language instead of the stock Material dialog.
class CrudForm extends StatelessWidget {
  const CrudForm({
    super.key,
    required this.title,
    required this.fields,
    this.values = const {},
    this.options = const {},
    this.errors = const {},
    this.onChanged,
    this.onSave,
    this.onDelete,
    this.extra,
    this.bare = false,
    this.dialogTitle,
    this.actions,
  });
  final String title;
  final List<UiFieldSpec> fields;
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onSave, onDelete;
  final Widget? extra;

  /// Render only the fields, leaving the dialog shell to the caller.
  final bool bare;

  /// Overrides [title] for the shell. Only read when [bare] is false.
  final String? dialogTitle;

  /// Replaces the default Delete / Cancel / Save actions. Only read when [bare]
  /// is false, and useful for previewing a different label set.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiFields(
            fields: fields,
            values: values,
            options: options,
            errors: errors,
            onChanged: onChanged,
          ),
          if (extra != null) ...[const ZRule(), const ZGap(24), extra!],
        ],
      ),
    );

    if (bare) return body;

    return ZDialog(
      title: dialogTitle ?? title,
      width: 520,
      actions: actions ??
          [
            if (onDelete != null)
              ZButton('Delete', secondary: true, onPressed: onDelete),
            ZButton(
              'Cancel',
              secondary: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
            ZButton('Save', onPressed: onSave),
          ],
      child: body,
    );
  }
}
