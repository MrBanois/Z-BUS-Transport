import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../presentation/features/auth/auth_page.dart';
import '../presentation/shared/ui_fields.dart';
import 'auth_controller.dart';

/// Rebuilds its subtree whenever the session changes and hands the current
/// [Session] to [builder].
///
/// The application shell is the only caller: it swaps between the sign-in
/// surface and the application chrome. Keeping the subscription here means no
/// widget below has to know that authentication exists at all.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.builder,
  });

  final AuthController auth;

  /// Receives `null` while signed out.
  final Widget Function(Session? session) builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (context, _) => builder(auth.session),
  );
}

/// The sign-in / registration surface, bound to an [AuthController].
///
/// This is the first thing the app shows. It owns only the uncommitted form
/// values; every decision (validation, the HTTP call, the permission mask) comes
/// from the controller, and a successful sign-in removes this subtree entirely
/// because [AuthGate] stops being asked to build it.
class AuthSurface extends StatefulWidget {
  const AuthSurface({super.key, required this.auth});

  final AuthController auth;

  @override
  State<AuthSurface> createState() => _AuthSurfaceState();
}

class _AuthSurfaceState extends State<AuthSurface> {
  /// Field keys match [AuthPage]'s `UiFieldSpec` names and the controller's
  /// validation keys, so a server message lands under the right control.
  final Map<String, Object?> _values = {
    'email': '',
    'password': '',
    'firstName': '',
    'lastName': '',
    'department': '',
    'position': '',
  };
  bool _remember = true;

  /// Set after a successful registration so the form can explain what happened.
  String? _notice;

  @override
  void dispose() {
    // The controller outlives this widget (the shell owns it), so any banner
    // from the previous attempt has to be dropped explicitly.
    widget.auth.clearError();
    super.dispose();
  }

  void _set(String name, Object? value) => setState(() {
    _values[name] = value;
    _notice = null;
    if (widget.auth.error != null) widget.auth.clearError();
  });

  Future<void> _submit() async {
    final email = '${_values['email']}';
    final password = '${_values['password']}';
    final registering = widget.auth.mode == AuthMode.register;

    final ok = await widget.auth.submit(
      email: email,
      password: password,
      firstName: '${_values['firstName']}',
      lastName: '${_values['lastName']}',
      department: '${_values['department']}',
      position: '${_values['position']}',
    );
    if (!mounted) return;

    if (!ok) {
      // A failed attempt keeps the typed values so the user can correct one
      // field, except the password, which is always cleared.
      setState(() => _values['password'] = '');
      return;
    }

    if (!registering) return;

    // Registration succeeded but produced no session: the account exists, so
    // sign straight in with the credentials just used rather than making the
    // user retype them. If that second call fails, fall back to the sign-in
    // form with the address already filled in.
    final entered = await widget.auth.signIn(email: email, password: password);
    if (!mounted) return;
    if (entered) return;

    setState(() {
      _values['password'] = '';
      _values['firstName'] = '';
      _values['lastName'] = '';
      _values['department'] = '';
      _values['position'] = '';
      _notice =
          'Account created. Sign in with the address and password you just used.';
    });
    await widget.auth.setMode(AuthMode.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    return AuthPage(
      register: auth.mode == AuthMode.register,
      values: _values,
      options: {
        'department': [
          for (final d in auth.departments) UiOption(d.id, d.label),
        ],
        'position': [
          for (final p in auth.positions) UiOption(p.id, p.label),
        ],
      },
      errors: auth.fieldErrors,
      error: auth.error ?? _notice,
      busy: auth.busy,
      optionsLoading: auth.dropdownsLoading,
      onChanged: _set,
      onSubmit: _submit,
      onToggleMode: () {
        setState(() => _notice = null);
        auth.toggleMode();
      },
      remember: _remember,
      onRememberChanged: (value) => setState(() => _remember = value),
    );
  }
}
