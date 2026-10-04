import 'api_client.dart';

/// A row of USER as the management screens see it.
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.departmentId,
    required this.departmentName,
    required this.positionId,
    required this.positionName,
    required this.isEmployee,
    required this.salary,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;

  /// Ids, which the dropdowns submit. See [resolveNames].
  final String departmentId;
  final String positionId;

  /// Names for display, filled in by `/api/user-linked` and left empty by
  /// `/api/user`.
  final String departmentName;
  final String positionName;

  final bool isEmployee;
  final double salary;

  String get fullName => '$firstName $lastName'.trim();

  static String text(Object? value) => '${value ?? ''}'.trim();

  /// Trimmed throughout, for the CHAR(5) reference ids: Oracle pads them, and a
  /// padded id never equals the dropdown value it should match.
  factory ManagedUser.fromJson(Map<String, dynamic> json) => ManagedUser(
    id: text(json['id']),
    firstName: text(json['f_name']),
    lastName: text(json['l_name']),
    email: text(json['email']),
    departmentId: text(json['dep']),
    departmentName: text(json['dep_name']),
    positionId: text(json['pos']),
    positionName: text(json['pos_name']),
    isEmployee: json['isemp'] == true,
    salary: _number(json['salary']),
  );

  static double _number(Object? value) => switch (value) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s.trim()) ?? 0,
    _ => 0,
  };

  /// A copy carrying the department and position names looked up from the lists
  /// the screen already holds.
  ///
  /// `/api/user` returns ids only, because the account screen is a filtered
  /// view of one table and joining on the server would mean the list endpoint
  /// carries reference data it has no other reason to know about. The
  /// management screens need both lists anyway to populate the dropdowns, so
  /// they resolve locally instead of paying for a second round trip per row.
  ManagedUser resolveNames({
    Map<String, String> departments = const {},
    Map<String, String> positions = const {},
  }) => ManagedUser(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    departmentId: departmentId,
    departmentName: departmentName.isNotEmpty
        ? departmentName
        : (departments[departmentId] ?? ''),
    positionId: positionId,
    positionName: positionName.isNotEmpty
        ? positionName
        : (positions[positionId] ?? ''),
    isEmployee: isEmployee,
    salary: salary,
  );
}

/// Administration access to the USER table.
///
/// Deliberately a different class from [UserRepository]. That one edits exactly
/// one account and cannot set ISEMP, SALARY or the password; this one edits any
/// account and can. Keeping them apart means the self-service screen cannot grow
/// an escalation path by accident: there is no method here that a member's
/// profile screen could call.
class UserAdminRepository {
  UserAdminRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  ApiClient get api => _api;

  /// Every account, staff and passengers alike.
  Future<List<ManagedUser>> all() async => [
    for (final row in await _api.users()) ManagedUser.fromJson(row),
  ];

  /// Only staff.
  Future<List<ManagedUser>> employees() async => [
    for (final row in await _api.users())
      if (row['isemp'] == true) ManagedUser.fromJson(row),
  ];

  /// [password] is required here and optional on [update], matching the two routes:
  /// a new account has no credential to inherit, so the caller decides what it is.
  ///
  /// It is still declared nullable because that is what lets the same
  /// `_password` helper drop a blank for the update route, and the caller that
  /// reaches this method with a null has already been rejected by the form.
  Future<String> create({
    required String firstName,
    required String lastName,
    required String email,
    required String department,
    required String position,
    required bool isEmployee,
    required double salary,
    String? password,
  }) => _api.createUser(
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    email: email.trim(),
    department: department.trim(),
    position: position.trim(),
    isEmployee: isEmployee,
    salary: salary,
    password: _password(password),
  );

  /// [password] is optional and means two different things by omission: leaving
  /// it out keeps the account's credential intact, which is what a rename or a
  /// department change sends. Supplying one resets it.
  Future<String> update({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String department,
    required String position,
    required bool isEmployee,
    required double salary,
    String? password,
  }) => _api.updateUser(
    id: id.trim(),
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    email: email.trim(),
    department: department.trim(),
    position: position.trim(),
    isEmployee: isEmployee,
    salary: salary,
    password: _password(password),
  );

  Future<String> delete(String id) => _api.deleteUser(id.trim());

  /// An empty or whitespace-only password is treated as absent rather than sent
  /// as `""`, which would be a reset to a credential nobody can type.
  String? _password(String? password) {
    final trimmed = password?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
