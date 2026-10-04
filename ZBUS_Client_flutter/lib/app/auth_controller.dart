import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';

/// Which of the two authentication surfaces is showing.
enum AuthMode { signIn, register }

/// What the shell needs to know about the sign-in attempt.
enum AuthStage {
  /// Nothing in flight; the form is idle.
  idle,

  /// A request is in flight. The form disables itself so a double tap cannot
  /// create two accounts.
  submitting,

  /// A request completed and the shell should enter.
  authenticated,

  /// A request failed. [AuthController.error] explains why.
  failed,
}

/// Owns authentication state for the shell.
///
/// This is the layer that was previously missing: the UI had callbacks but
/// nothing behind them, so the app always started on a page nobody had earned.
/// It holds no widgets and performs no authorization decisions beyond comparing
/// the session mask against [kPermissionOrder].
class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository})
    : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  AuthRepository get repository => _repository;

  Session? _session;
  Session? get session => _session;

  bool get isSignedIn => _session != null;

  AuthMode _mode = AuthMode.signIn;
  AuthMode get mode => _mode;

  AuthStage _stage = AuthStage.idle;
  AuthStage get stage => _stage;

  /// True while a request is in flight.
  bool get busy => _stage == AuthStage.submitting;

  String? _error;
  String? get error => _error;

  /// Field-level messages keyed by the auth form's field names, matching the
  /// keys [AuthPage] renders errors under.
  Map<String, String> _fieldErrors = const {};
  Map<String, String> get fieldErrors => _fieldErrors;

  /// Passenger-facing dropdown data for the register form, loaded on demand.
  List<ChoiceOption> _departments = const [];
  List<ChoiceOption> _positions = const [];
  List<ChoiceOption> get departments => _departments;
  List<ChoiceOption> get positions => _positions;

  bool _dropdownsLoading = false;
  bool get dropdownsLoading => _dropdownsLoading;

  bool _dropdownsLoaded = false;
  bool get dropdownsLoaded => _dropdownsLoaded;

  // ---------------------------------------------------------------------------
  // Mode
  // ---------------------------------------------------------------------------

  /// Switch between sign-in and registration.
  Future<void> setMode(AuthMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    _error = null;
    _fieldErrors = const {};
    notifyListeners();
    if (mode == AuthMode.register) await loadDropdowns();
  }

  void toggleMode() => setMode(
    _mode == AuthMode.signIn ? AuthMode.register : AuthMode.signIn,
  );

  // ---------------------------------------------------------------------------
  // Dropdowns
  // ---------------------------------------------------------------------------

  /// Fetch the passenger-facing departments and positions.
  ///
  /// Only `ISEMP = 'F'` rows come back, so the form cannot offer a staff
  /// department. Failures are surfaced as a banner but do not block typing:
  /// the server re-validates the choice on submit regardless.
  Future<void> loadDropdowns({bool force = false}) async {
    if (_dropdownsLoading) return;
    if (_dropdownsLoaded && !force) return;
    _dropdownsLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.passengerDepartments(),
        _repository.passengerPositions(),
      ]);
      _departments = results[0];
      _positions = results[1];
      _dropdownsLoaded = true;
      _error = null;
    } on ApiException catch (e) {
      // A banner, not a field error: the user can still fill the rest of the
      // form, and the server re-validates the choice on submit.
      _error = e.message;
    } finally {
      _dropdownsLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  /// Sign in. On success the session carries the decoded permission mask.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) {
      return _fail(fieldErrors: const {'email': 'Enter your institutional email'});
    }
    if (password.isEmpty) {
      return _fail(fieldErrors: const {'password': 'Enter your password'});
    }

    _begin();
    try {
      _session = await _repository.login(email: email, password: password);
      _stage = AuthStage.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      // A credential failure belongs on the email field, not in a banner: that
      // is where the user is looking.
      final onField = e.isUnauthorized
          ? const {'email': 'Email or password is incorrect'}
          : const <String, String>{};
      return _fail(message: e.isUnauthorized ? null : e.message, fieldErrors: onField);
    }
  }

  /// Register a passenger account.
  ///
  /// [onRegistered] receives the new user id so the shell can auto sign in or
  /// show it. The server enforces the ISEMP rules; this only rejects the
  /// obviously empty cases so a round trip is not wasted.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String department,
    required String position,
  }) async {
    final errors = <String, String>{};
    if (firstName.trim().isEmpty) errors['firstName'] = 'Required';
    if (lastName.trim().isEmpty) errors['lastName'] = 'Required';
    if (email.trim().isEmpty) {
      errors['email'] = 'Enter your institutional email';
    }
    if (password.isEmpty) {
      errors['password'] = 'Enter a password';
    } else if (password.length < 6) {
      // Mirrors MIN_PASSWORD_LENGTH on the server so the user is told here
      // rather than after a round trip.
      errors['password'] = 'At least 6 characters';
    }
    if (department.isEmpty) errors['department'] = 'Choose a department';
    if (position.isEmpty) errors['position'] = 'Choose a position';
    if (errors.isNotEmpty) return _fail(fieldErrors: errors);

    _begin();
    try {
      await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        department: department,
        position: position,
      );
      _stage = AuthStage.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      // 409 is a field error on the address itself.
      final onField = e.isConflict ? {'email': e.message} : const <String, String>{};
      return _fail(message: e.isConflict ? null : e.message, fieldErrors: onField);
    }
  }

  /// Run the sign-in or register request matching the current [mode].
  Future<bool> submit({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
    String department = '',
    String position = '',
  }) => _mode == AuthMode.signIn
      ? signIn(email: email, password: password)
      : register(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          department: department,
          position: position,
        );

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  /// Sign in with an already-constructed session. For tests and for restoring a
  /// persisted session.
  void adopt(Session session) {
    _session = session;
    _stage = AuthStage.authenticated;
    _error = null;
    _fieldErrors = const {};
    notifyListeners();
  }

  /// Drop the session and return to the sign-in surface.
  void signOut() {
    _session = null;
    _mode = AuthMode.signIn;
    _stage = AuthStage.idle;
    _error = null;
    _fieldErrors = const {};
    _dropdownsLoaded = false;
    _departments = const [];
    _positions = const [];
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------

  void _begin() {
    _stage = AuthStage.submitting;
    _error = null;
    _fieldErrors = const {};
    notifyListeners();
  }

  bool _fail({
    String? message,
    Map<String, String> fieldErrors = const {},
  }) {
    _stage = AuthStage.failed;
    _error = message;
    _fieldErrors = fieldErrors;
    notifyListeners();
    return false;
  }
}
