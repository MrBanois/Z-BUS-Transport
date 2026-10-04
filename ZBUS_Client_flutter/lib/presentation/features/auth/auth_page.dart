import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/ui_fields.dart';

/// A controlled sign-in / registration surface.
///
/// Supply [values], [options], [errors], [error] and [busy] from an
/// [AuthController]; there is no demo email or password bypass here. The
/// controller owns validation, the HTTP call and the permission mask.
///
/// The layout mirrors the reference sign-in: a full-bleed editorial panel beside
/// the form on wide viewports, collapsing to the form alone on phones.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    this.register = false,
    this.values = const {},
    this.options = const {},
    this.errors = const {},
    this.error,
    this.busy = false,
    this.optionsLoading = false,
    this.onChanged,
    this.onSubmit,
    this.onToggleMode,
    this.remember = true,
    this.onRememberChanged,
  });
  final bool register;
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;

  /// A request-level failure, shown above the form. Field problems belong in
  /// [errors] instead.
  final String? error;

  /// Disables the controls while a request is in flight.
  final bool busy;

  /// Disables the two dropdowns while the passenger-facing lists load.
  final bool optionsLoading;

  final void Function(String, Object?)? onChanged;
  final VoidCallback? onSubmit, onToggleMode;
  final bool remember;
  final ValueChanged<bool>? onRememberChanged;
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide) const Expanded(child: _EditorialPanel()),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 64 : 25),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!wide) ...[const _BrandMark(), const ZGap(70)],
                    Row(
                      children: [
                        const Expanded(
                          child: ZLabel(
                            'MEMBER ACCESS / ZBUS',
                            color: ZColors.accent,
                          ),
                        ),
                        if (busy) const ZLabel('WORKING', color: ZColors.muted),
                      ],
                    ),
                    const ZGap(20),
                    Text(
                      register ? 'JOIN THE\nNETWORK.' : 'WELCOME\nABOARD.',
                      style: ZTheme.display(wide ? 76 : 60),
                    ),
                    const ZGap(19),
                    Text(
                      register
                          ? 'Create a passenger account to reserve seats and '
                                'follow your trips.'
                          : 'Sign in to manage the network or find your next '
                                'ride.',
                      style: const TextStyle(color: ZColors.muted, height: 1.5),
                    ),
                    const ZGap(36),
                    const ZRule(),
                    const ZGap(25),
                    UiFields(
                      fields: [
                        const UiFieldSpec('email', 'Institutional email'),
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
                      onChanged: busy ? null : onChanged,
                    ),
                    if (error != null) ...[
                      const ZGap(18),
                      ZNotice(
                        'Could not continue',
                        error!,
                        color: ZColors.accent,
                        icon: Icons.error_outline,
                      ),
                    ],
                    if (register && optionsLoading) ...[
                      const ZGap(18),
                      const ZNotice(
                        'Loading options',
                        'Reading the passenger departments and positions. '
                        'Staff departments are excluded by the server.',
                        color: ZColors.muted,
                      ),
                    ],
                    if (onRememberChanged != null) ...[
                      const ZGap(2),
                      Row(
                        children: [
                          ZSwitch(
                            value: remember,
                            onChanged: onRememberChanged,
                            activeColor: ZColors.ink,
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Keep me signed in',
                            style: TextStyle(
                              color: ZColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const ZGap(20),
                    ZButton(
                      // Relabelled while in flight, and disabled, so a double tap
                      // cannot register the same address twice.
                      busy
                          ? (register ? 'Creating' : 'Signing in')
                          : (register ? 'Create account' : 'Enter ZBus'),
                      onPressed: busy ? null : onSubmit,
                      icon: busy ? null : Icons.arrow_forward,
                    ),
                    const ZGap(10),
                    ZButton(
                      register ? 'Back to sign in' : 'Register',
                      secondary: true,
                      onPressed: busy ? null : onToggleMode,
                    ),
                    const ZGap(18),
                    const ZNotice(
                      'Permission-based access',
                      'Every screen is reachable only when the signed-in '
                      'position grants it. Authorization is enforced by your '
                      'application and backend layers.',
                      color: ZColors.success,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorialPanel extends StatelessWidget {
  const _EditorialPanel();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // The panel is fixed-height decorative copy, so it has to degrade on short
      // viewports (landscape phones, small browser windows) instead of
      // overflowing. Type and padding step down; the least important copy goes
      // first, and the full-bleed composition is kept on normal displays.
      final height = box.maxHeight;
      final tiny = height < 540;
      final tight = height < 760;
      final pad = tiny ? 24.0 : tight ? 34.0 : 52.0;
      final display = tiny ? 40.0 : tight ? 60.0 : 92.0;
      final g1 = tiny ? 12.0 : tight ? 18.0 : 25.0;
      final g2 = tiny ? 14.0 : tight ? 20.0 : 28.0;
      final g3 = tiny ? 12.0 : tight ? 16.0 : 22.0;
      return Container(
        padding: EdgeInsets.all(pad),
        decoration: const BoxDecoration(
          color: ZColors.surface,
          border: Border(right: BorderSide(color: ZColors.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BrandMark(scale: tiny ? 0.8 : 1),
            const Spacer(),
            const ZLabel(
              'MAHANAKORN UNIVERSITY OF TECHNOLOGY',
              color: ZColors.accent,
            ),
            ZGap(g1),
            Text('THE CITY,\nCONNECTED.', style: ZTheme.display(display)),
            ZGap(g2),
            const ZRule(),
            ZGap(g3),
            if (!tiny)
              Flexible(
                child: Text(
                  'Reliable rides across Nong Chok. One network for the people '
                  'who move it.',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ZColors.muted,
                    fontSize: tiny ? 14 : 17,
                    height: 1.5,
                  ),
                ),
              ),
            const Spacer(),
            if (!tiny)
              const ZLabel('01 / PLAN    02 / RIDE    03 / ARRIVE'),
          ],
        ),
      );
    },
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.scale = 1});
  final double scale;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 13 * scale,
        height: 13 * scale,
        decoration: const BoxDecoration(
          color: ZColors.accent,
          shape: BoxShape.circle,
        ),
      ),
      SizedBox(width: 9 * scale),
      Text('ZBUS', style: ZTheme.display(30 * scale)),
      SizedBox(width: 7 * scale),
      Text(
        'TRANSPORT',
        style: ZTheme.mono(8 * scale, color: ZColors.ink),
      ),
    ],
  );
}