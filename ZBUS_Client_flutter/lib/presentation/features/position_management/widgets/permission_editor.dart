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
  Widget build(BuildContext context) {
    if (permissions.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ZLabel('Permissions', color: ZColors.accent),
          ZGap(16),
          ZEmpty('No permissions available', ''),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ZLabel('Permissions', color: ZColors.accent),
        const ZGap(16),
        for (final entry in permissions.entries)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ZSwitch(
                      value: entry.value,
                      onChanged: onChanged == null
                          ? null
                          : (v) => onChanged!(entry.key, v),
                    ),
                  ],
                ),
              ),
              const ZRule(),
            ],
          ),
      ],
    );
  }
}