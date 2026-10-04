import '../presentation/shared/permissions.dart';
import 'api_client.dart';
import 'choice_option.dart';

export 'choice_option.dart';

/// The signed-in account, as returned by `POST /api/login`.
class Session {
  Session({
    required this.id,
    required this.name,
    required this.email,
    required this.permissionMask,
  });

  final String id;
  final String name;
  final String email;

  /// The raw 16 character `'0'`/`'1'` mask from `POSITION.PERMISSION`.
  final String permissionMask;

  /// The screens this position unlocks, decoded once at sign-in so the
  /// navigation does not re-parse the mask on every frame.
  late final Set<String> permissions = permissionMaskToSet(permissionMask);

  bool can(String screen) => permissions.contains(screen);

  /// A position whose mask is missing or malformed unlocks nothing.
  bool get hasAnyPermission => permissions.isNotEmpty;
}

/// Authentication and the passenger-facing dropdown data.
///
/// Holds no session: the caller keeps the [Session] it gets back. Swapping this
/// for a fake is the whole point of the seam.
class AuthRepository {
  AuthRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  ApiClient get api => _api;

  /// Sign in and decode the returned mask.
  ///
  /// Throws [ApiException] with `isUnauthorized` set for bad credentials and
  /// [ApiUnreachable] when the server cannot be contacted.
  Future<Session> login({required String email, required String password}) async {
    final body = await _api.login(email.trim(), password);
    final user = body['user'];
    if (user is! Map<String, dynamic>) {
      throw ApiException('Sign in returned an unexpected response.');
    }
    return Session(
      id: '${user['id'] ?? ''}'.trim(),
      name: '${user['name'] ?? ''}'.trim(),
      email: '${user['email'] ?? email}'.trim(),
      permissionMask: '${user['permission'] ?? ''}'.trim(),
    );
  }

  /// Create a passenger account and return the generated user id.
  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String department,
    required String position,
  }) => _api.register(
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    email: email.trim(),
    password: password,
    department: department.trim(),
    position: position.trim(),
  );

  /// Only departments flagged ISEMP = 'F', so staff departments never appear.
  Future<List<ChoiceOption>> passengerDepartments() async {
    final rows = await _api.passengerDepartments();
    return [
      for (final row in rows)
        ChoiceOption(
          id: '${row['id'] ?? ''}'.trim(),
          name: '${row['name'] ?? ''}'.trim(),
        ),
    ];
  }

  /// Only positions flagged ISEMP = 'F', so a signup cannot be issued an
  /// employee position and the screens it unlocks.
  Future<List<ChoiceOption>> passengerPositions() async {
    final rows = await _api.passengerPositions();
    return [
      for (final row in rows)
        ChoiceOption(
          id: '${row['id'] ?? ''}'.trim(),
          name: '${row['name'] ?? ''}'.trim(),
        ),
    ];
  }
}
