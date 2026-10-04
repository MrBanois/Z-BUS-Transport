import 'api_client.dart';
import 'choice_option.dart';

/// The signed-in member's own record, from `GET /api/user/profile/{id}`.
///
/// Holds ids as well as names: the ids are what the dropdowns submit, and the
/// names are what the screen shows. Keeping both avoids a second lookup just to
/// label a field.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.departmentId,
    required this.departmentName,
    required this.positionId,
    required this.positionName,
    required this.isEmployee,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String departmentId;
  final String departmentName;
  final String positionId;
  final String positionName;

  /// Whether the account is staff. Drives whether the assignment fields are
  /// editable; the server enforces it independently.
  final bool isEmployee;

  String get fullName => '$firstName $lastName'.trim();

  static String text(Object? value) => '${value ?? ''}'.trim();

  // Every value is trimmed on the way in. DEPARTMENT.ID and POSITION.ID are
  // CHAR(5), so Oracle pads them: a stored 'D0011 ' compares unequal to a
  // dropdown value of 'D0011', which would leave the select showing a blank.
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: text(json['id']),
    firstName: text(json['f_name']),
    lastName: text(json['l_name']),
    email: text(json['email']),
    departmentId: text(json['dep']),
    departmentName: text(json['dep_name']),
    positionId: text(json['pos']),
    positionName: text(json['pos_name']),
    isEmployee: json['isemp'] == true,
  );
}

/// Reads and writes the signed-in member's own profile.
///
/// Deliberately separate from [AuthRepository] and from the management
/// repositories: this is the only repository the account screen talks to, and
/// it can only touch one account, the one it is given an id for.
class UserRepository {
  UserRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  ApiClient get api => _api;

  /// Throws [ApiException] with `statusCode == 404` when the id does not exist.
  Future<UserProfile> profile(String userId) async {
    if (userId.trim().isEmpty) {
      throw ApiException('There is no signed-in account to load.');
    }
    return UserProfile.fromJson(await _api.profile(userId.trim()));
  }

  /// Save the editable subset. [department] and [position] may be null to leave
  /// the stored assignment alone.
  ///
  /// Throws [ApiException] with `statusCode == 400` for a rejected name or
  /// assignment and 403 for an employee attempting to change their own.
  Future<String> save({
    required String userId,
    required String firstName,
    required String lastName,
    String? department,
    String? position,
  }) => _api.saveProfile(
    userId: userId,
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    department: department?.trim(),
    position: position?.trim(),
  );

  /// The passenger-facing assignment lists, used to populate the dropdowns.
  ///
  /// The ISEMP = 'F' filter is the server's, not a client-side one, so a stale
  /// build cannot offer an employee position to a passenger.
  Future<({List<ChoiceOption> departments, List<ChoiceOption> positions})>
      passengerAssignmentOptions() async {
    // Sequential rather than parallel: this pairs with a single screen read and
    // the lists are small. Errors are handled together so one failure does not
    // leave half the form populated.
    final departments = await _api.passengerDepartments();
    final positions = await _api.passengerPositions();
    return (
      departments: [
        for (final row in departments)
          ChoiceOption(
            id: UserProfile.text(row['id']),
            name: UserProfile.text(row['name']),
          ),
      ],
      positions: [
        for (final row in positions)
          ChoiceOption(
            id: UserProfile.text(row['id']),
            name: UserProfile.text(row['name']),
          ),
      ],
    );
  }
}
