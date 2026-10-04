import 'package:flutter/material.dart';

import '../../../shared/crud_form.dart';
import '../../../shared/ui_fields.dart';
import 'route_stations_editor.dart';

/// Supply generated IDs as read-only values. Persist via onSave in your presenter.
class RouteForm extends StatelessWidget {
  const RouteForm({
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
    title: 'Route',
    fields: const [
      UiFieldSpec('id', 'ID', readOnly: true, hint: 'Assigned automatically'),
      UiFieldSpec('name', 'Name'),
      UiFieldSpec('active', 'Active', kind: UiFieldKind.toggle),
    ],
    values: values,
    options: options,
    errors: errors,
    onChanged: onChanged,
    onSave: onSave,
    onDelete: onDelete,
    extra: extra ?? const RouteStationsEditor(),
  );
}
