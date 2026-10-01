import 'package:flutter/material.dart';

import '../../../shared/design_system.dart';

/// Pass permission labels and selected flags. Authorization must be enforced by
/// your application/backend; these switches only report user interaction.
class PermissionEditor extends StatelessWidget {
  const PermissionEditor({
    super.key,
    this.permissions = const {},
    this.onChanged,
  });
  final Map<String, bool> permissions;
  final void Function(String, bool)? onChanged;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const ZLabel('Permissions'),
      if (permissions.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No permissions available'),
        ),
      for (final p in permissions.entries)
        Row(
          children: [
            Expanded(child: Text(p.key)),
            Switch(
              value: p.value,
              onChanged: onChanged == null ? null : (v) => onChanged!(p.key, v),
            ),
          ],
        ),
    ],
  );
}
