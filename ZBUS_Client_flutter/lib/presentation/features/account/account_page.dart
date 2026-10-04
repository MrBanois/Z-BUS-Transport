import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/page_copy.dart';
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

  String get _displayName {
    final first = values['firstName']?.toString().trim() ?? '';
    final last = values['lastName']?.toString().trim() ?? '';
    final joined = '$first $last'.trim();
    return joined.isEmpty ? 'MEMBER' : joined;
  }

  @override
  Widget build(BuildContext context) => WorkflowPage(
    title: memberAccount.headline,
    section: 'MEMBER',
    index: memberAccount.index,
    kicker: memberAccount.kicker,
    description: memberAccount.standfirst,
    children: [
      ZColumns(
        desktopColumns: 2,
        children: [
          ZPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ZLabel('MEMBER CARD / MUT', color: ZColors.accent),
                const ZGap(27),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: ZColors.surface2,
                  child: Text('NM', style: ZTheme.display(28)),
                ),
                const ZGap(25),
                Text(
                  _displayName.toUpperCase(),
                  style: ZTheme.display(35),
                ),
                const ZGap(10),
                Text(
                  values['email']?.toString() ?? '',
                  style: const TextStyle(color: ZColors.muted),
                ),
                const ZGap(28),
                const ZRule(),
                const ZGap(20),
                ZKeyValue(
                  'ACCOUNT TYPE',
                  isEmployee ? 'EMPLOYEE' : 'PASSENGER',
                ),
                const ZGap(13),
                ZKeyValue(
                  'MEMBER ID',
                  values['id']?.toString() ?? '—',
                ),
                const ZGap(13),
                ZKeyValue(
                  'POSITION',
                  values['position']?.toString() ?? '—',
                ),
              ],
            ),
          ),
          ZPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ZLabel('PROFILE DETAILS', color: ZColors.accent),
                const ZGap(24),
                UiFields(
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
                const ZRule(),
                const ZGap(22),
                ZButton('Save profile', onPressed: onSave),
              ],
            ),
          ),
        ],
      ),
      const ZNotice(
        'Read-only assignments',
        'Employee department and position are assigned by administration. '
        'Passengers may change their own.',
        color: ZColors.success,
      ),
    ],
  );
}