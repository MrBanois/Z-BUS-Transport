import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/page_copy.dart';
import '../../shared/ui_fields.dart';
import '../../shared/workflow_page.dart';

/// The My account screen, as a controlled view.
///
/// It is told what the record is, what the member has typed, which controls are
/// live and what went wrong, and it hands every change back through [onChanged].
/// It makes no request, decides nothing about what may be edited and holds no
/// draft of its own: [AccountController] owns all of that. The defaults render a
/// typable form for layout preview, which is why every callback is optional.
///
/// Field names match the controller's keys: `firstName`, `lastName`,
/// `department`, `position`.
class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    this.loading = false,
    this.saving = false,
    this.failed = false,
    this.dirty = false,
    this.optionsLoading = false,
    this.isEmployee = false,
    this.memberId = '',
    this.email = '',
    this.departmentName = '',
    this.positionName = '',
    this.grantedScreens = const [],
    this.values = const {},
    this.options = const {},
    this.errors = const {},
    this.error,
    this.notice,
    this.onChanged,
    this.onSave,
    this.onRetry,
    this.onDiscard,
  });

  /// The record is being fetched. Distinct from [failed] so a screen mid-request
  /// cannot be mistaken for a member with no name.
  final bool loading;

  /// A save is in flight.
  final bool saving;

  /// The record could not be fetched.
  final bool failed;

  /// The form differs from what is stored, which is what enables the save button.
  final bool dirty;

  /// The assignment dropdowns are still being fetched.
  final bool optionsLoading;

  /// Whether the member is staff. Their assignment is read-only; the server
  /// refuses such a change independently.
  final bool isEmployee;

  /// Read-only identity shown on the member card.
  final String memberId, email, departmentName, positionName;

  /// The screens this member's position unlocks, in the canonical bit order.
  final List<String> grantedScreens;

  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;

  /// A request failed in a way that is not tied to one field.
  final String? error;

  /// A result worth keeping on screen, such as a successful save.
  final String? notice;

  final void Function(String field, Object? value)? onChanged;
  final VoidCallback? onSave;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  /// Disabled while a request is in flight, so a double tap cannot send the same
  /// update twice.
  bool get _busy => loading || saving;

  String _text(String key) => '${values[key] ?? ''}'.trim();

  /// Uppercased as the design system renders every other name on this card. Falls
  /// back to the member id's first character so a nameless record still shows a
  /// real initial instead of an empty circle.
  String get _displayName {
    final joined = '${_text('firstName')} ${_text('lastName')}'.trim();
    if (joined.isNotEmpty) return joined.toUpperCase();
    return memberId.isEmpty ? 'MEMBER' : 'MEMBER ${memberId.toUpperCase()}';
  }

  String get _initial {
    final first = _text('firstName');
    if (first.isNotEmpty) return first[0].toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) => WorkflowPage(
    title: memberAccount.headline,
    section: 'MEMBER',
    index: memberAccount.index,
    kicker: memberAccount.kicker,
    description: memberAccount.standfirst,
    children: [if (loading) _loading() else if (failed) _failure() else _loaded()],
  );

  // -----------------------------------------------------------------------------
  // States
  // -----------------------------------------------------------------------------

  /// A placeholder rather than an empty form: an all-blank member card reads as
  /// "you have no name" when it actually means "not fetched yet".
  Widget _loading() => const ZPanel(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZLabel('PROFILE / LOADING', color: ZColors.accent),
          ZGap(20),
          ZEmpty('Loading profile', 'Fetching your record from the server.'),
        ],
      ),
    ),
  );

  Widget _failure() => ZPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZLabel('PROFILE / UNAVAILABLE', color: ZColors.accent),
        const ZGap(20),
        ZEmpty(
          'Could not load your profile',
          error ?? 'The server did not answer. Nothing has been changed.',
          action: ZButton(
            'Try again',
            onPressed: _busy ? null : onRetry,
            icon: Icons.refresh,
          ),
        ),
      ],
    ),
  );

  Widget _loaded() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ZColumns(
        desktopColumns: 2,
        children: [_card(), _form()],
      ),
      if (notice != null)
        ZNotice(
          'Saved',
          notice!,
          color: ZColors.success,
          icon: Icons.check_circle_outline,
        ),
      if (error != null)
        ZNotice(
          'Not saved',
          error!,
          color: ZColors.accent,
          icon: Icons.error_outline,
        ),
      _access(),
      const ZNotice(
        'Read-only assignments',
        'Employee department and position are assigned by administration. '
        'Passengers may change their own.',
        color: ZColors.success,
      ),
    ],
  );

  // -----------------------------------------------------------------------------
  // Member card
  // -----------------------------------------------------------------------------

  Widget _card() => ZPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZLabel('MEMBER CARD / MUT', color: ZColors.accent),
        const ZGap(27),
        CircleAvatar(
          radius: 40,
          backgroundColor: ZColors.surface2,
          child: Text(_initial, style: ZTheme.display(28)),
        ),
        const ZGap(25),
        Text(_displayName, style: ZTheme.display(35)),
        const ZGap(10),
        Text(
          email.isEmpty ? '—' : email,
          style: const TextStyle(color: ZColors.muted),
        ),
        const ZGap(28),
        const ZRule(),
        const ZGap(20),
        ZKeyValue('ACCOUNT TYPE', isEmployee ? 'EMPLOYEE' : 'PASSENGER'),
        const ZGap(13),
        ZKeyValue('MEMBER ID', memberId.isEmpty ? '—' : memberId),
        const ZGap(13),
        ZKeyValue(
          'DEPARTMENT',
          departmentName.isEmpty ? '—' : departmentName,
        ),
        const ZGap(13),
        ZKeyValue('POSITION', positionName.isEmpty ? '—' : positionName),
      ],
    ),
  );

  // -----------------------------------------------------------------------------
  // Form
  // -----------------------------------------------------------------------------

  Widget _form() => ZPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZLabel('PROFILE DETAILS', color: ZColors.accent),
        const ZGap(24),
        UiFields(
          fields: [
            const UiFieldSpec('id', 'Member ID', readOnly: true),
            const UiFieldSpec('firstName', 'First name'),
            const UiFieldSpec('lastName', 'Last name'),
            UiFieldSpec(
              'department',
              'Department',
              kind: UiFieldKind.select,
              readOnly: _busy || isEmployee,
              // Says the field is pending rather than leaving an empty box that
              // looks like an unselected value.
              hint: optionsLoading ? 'Loading departments…' : 'Choose a department',
            ),
            UiFieldSpec(
              'position',
              'Position',
              kind: UiFieldKind.select,
              readOnly: _busy || isEmployee,
              hint: optionsLoading ? 'Loading positions…' : 'Choose a position',
            ),
          ],
          values: values,
          options: options,
          errors: errors,
          onChanged: _busy ? null : onChanged,
        ),
        const ZRule(),
        const ZGap(22),
        // The save button is enabled only when there is something to send, so a
        // no-op round trip is not possible from the UI.
        ZButton(
          saving ? 'Saving…' : 'Save profile',
          icon: saving ? null : Icons.check,
          onPressed: _busy || !dirty ? null : onSave,
        ),
        if (dirty) ...[
          const ZGap(12),
          ZButton(
            'Discard changes',
            secondary: true,
            onPressed: _busy ? null : onDiscard,
          ),
        ],
      ],
    ),
  );

  // -----------------------------------------------------------------------------
  // Access
  // -----------------------------------------------------------------------------

  /// Makes the permission mask legible from the member's own side: the sidebar
  /// reports the count, this lists which screens those bits actually are.
  Widget _access() => ZPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const ZLabel('SCREEN ACCESS', color: ZColors.accent),
            const Spacer(),
            ZLabel('${grantedScreens.length} / 16'),
          ],
        ),
        const ZGap(18),
        if (grantedScreens.isEmpty)
          const Text(
            'Your position unlocks no management screens. Passenger screens and '
            'your account remain available.',
            style: TextStyle(color: ZColors.muted, fontSize: 13, height: 1.5),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final screen in grantedScreens)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: ZColors.line),
                  ),
                  child: Text(
                    screen.toUpperCase(),
                    style: ZTheme.mono(10, color: ZColors.ink),
                  ),
                ),
            ],
          ),
        const ZGap(18),
        const ZRule(),
        const ZGap(16),
        const Text(
          'These come from your position and are read at sign-in. Changing your '
          'position here takes effect the next time you sign in.',
          style: TextStyle(color: ZColors.muted, fontSize: 12, height: 1.5),
        ),
      ],
    ),
  );
}
