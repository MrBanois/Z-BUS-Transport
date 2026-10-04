import 'package:flutter/material.dart';

import 'design_system.dart';
import 'ui_fields.dart';

/// Reusable create/edit dialog. The parent owns the draft, validation, generated
/// ID and save/delete use cases. Rebuild with errors on a failed submission.
///
/// Uses the squared [ZDialog] shell so create/edit flows match the rest of the
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
  });
  final String title;
  final List<UiFieldSpec> fields;
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onSave, onDelete;
  final Widget? extra;
  @override
  Widget build(BuildContext context) => ZDialog(
    title: title,
    width: 520,
    actions: [
      if (onDelete != null)
        ZButton('Delete', secondary: true, onPressed: onDelete),
      ZButton(
        'Cancel',
        secondary: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
      ZButton('Save', onPressed: onSave),
    ],
    child: SingleChildScrollView(
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
    ),
  );
}