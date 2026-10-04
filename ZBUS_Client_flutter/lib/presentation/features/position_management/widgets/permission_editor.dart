import 'package:flutter/material.dart';

import '../../../shared/design_system.dart';
import '../../../shared/permissions.dart';

/// Renders the 16 screens a position can unlock.
///
/// Pass the raw `POSITION.PERMISSION` mask through [mask]; the editor decodes it
/// with [permissionMaskToMap] so every row is labelled in the canonical
/// [kPermissionOrder] regardless of what the backend stored. Nothing here
/// decides authorization: toggling a switch only reports intent through
/// [onChanged], and the presenter persists the re-encoded mask.
class PermissionEditor extends StatelessWidget {
  const PermissionEditor({
    super.key,
    this.mask,
    this.permissions,
    this.onChanged,
    this.editable = true,
  });

  /// Raw 16 character `'0'`/`'1'` mask from the backend.
  ///
  /// Ignored when [permissions] is supplied, so a presenter that already holds a
  /// decoded map does not have to re-encode it just to render.
  final String? mask;

  /// Already-decoded selection, when the caller has one.
  final Map<String, bool>? permissions;

  /// Reports a single screen toggled. The presenter re-encodes and persists.
  final void Function(String, bool)? onChanged;

  /// When false the switches render read-only, for a view-only screen.
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final selection =
        permissions ?? permissionMaskToMap(mask);
    final granted = selection.values.where((v) => v).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: ZLabel('Permissions', color: ZColors.accent),
            ),
            Text(
              '$granted / $kPermissionLength',
              style: ZTheme.mono(11, color: ZColors.muted),
            ),
          ],
        ),
        const ZGap(16),
        // Grouped so the two halves of the catalogue read as the two halves of
        // the product: back-office screens, then passenger screens.
        for (final group in const [
          <String>[
            'Manage departments',
            'Manage positions',
            'Manage users',
            'Manage employees',
            'Manage routes',
            'Manage stations',
            'Manage schedules',
            'Manage vehicles',
            'Statistic reports',
          ],
          <String>[
            'Find a trip',
            'Reserve seats',
            'My reservations',
            'My driving schedule',
            'Active trip',
            'Scan passenger QR',
            'Completed trip',
          ],
        ]) ...[
          for (final screen in group)
            _PermissionRow(
              screen: screen,
              value: selection[screen] ?? false,
              onChanged: onChanged,
              enabled: editable,
            ),
        ],
        const ZGap(10),
        ZNotice(
          'Stored as a 16-bit mask',
          'Bit 0 is the left-most character and unlocks "$kPermissionOrder" first. '
          'The server and this client share that order.',
          color: ZColors.muted,
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.screen,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final String screen;
  final bool value;
  final void Function(String, bool)? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // A null callback means read-only regardless of `editable`, matching how the
    // rest of the design system treats a missing handler.
    final editable = enabled && onChanged != null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              // The label half of the row is a target too: sixteen small switches
              // stacked in a dialog are a poor tap surface otherwise.
              Expanded(
                child: Semantics(
                  toggled: value,
                  enabled: editable,
                  button: editable,
                  child: MouseRegion(
                    cursor: editable
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: InkWell(
                      onTap: editable ? () => onChanged!(screen, !value) : null,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              (kPermissionOrder.indexOf(screen) + 1)
                                  .toString()
                                  .padLeft(2, '0'),
                              style: ZTheme.mono(11, color: ZColors.muted),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              screen,
                              style: TextStyle(
                                fontSize: 14,
                                color: value ? ZColors.ink : ZColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ZSwitch(
                value: value,
                onChanged: editable ? (v) => onChanged!(screen, v) : null,
              ),
            ],
          ),
        ),
        const ZRule(),
      ],
    );
  }
}
