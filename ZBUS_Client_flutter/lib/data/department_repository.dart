import 'api_client.dart';
import 'choice_option.dart';

/// A row of DEPARTMENT, from `GET /api/department`.
class DepartmentRecord {
  const DepartmentRecord({
    required this.id,
    required this.name,
    required this.isEmployee,
  });

  final String id;
  final String name;

  /// ISEMP. False marks a department that public registration may select, which
  /// is why this flag is editable on the administration screen and is not on the
  /// account screen.
  final bool isEmployee;

  static String text(Object? value) => '${value ?? ''}'.trim();

  /// Trimmed, because DEPARTMENT.ID is CHAR(5) and Oracle pads it. A padded id
  /// never equals the unpadded one the table displays, and never matches as a
  /// route parameter.
  factory DepartmentRecord.fromJson(Map<String, dynamic> json) =>
      DepartmentRecord(
        id: text(json['id']),
        name: text(json['name']),
        isEmployee: json['isemp'] == true,
      );

  ChoiceOption get option => ChoiceOption(id: id, name: name);
}

/// Reads and writes DEPARTMENT.
///
/// Separate from [UserRepository] because it is a different authorization
/// story: this one is reached from a screen that requires the "Manage
/// departments" permission, not from a member looking at their own account.
class DepartmentRepository {
  DepartmentRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  ApiClient get api => _api;

  Future<List<DepartmentRecord>> all() async => [
    for (final row in await _api.departments()) DepartmentRecord.fromJson(row),
  ];

  /// `isEmployee` defaults to true on the server. Pass false deliberately to
  /// make a department selectable on the public registration form.
  Future<String> create({
    required String name,
    required bool isEmployee,
  }) => _api.createDepartment(name: name.trim(), isEmployee: isEmployee);

  /// A full replacement: the server takes name and ISEMP together, so a rename
  /// that should not publish the department has to resend `isEmployee: false`.
  Future<String> update({
    required String id,
    required String name,
    required bool isEmployee,
  }) => _api.updateDepartment(
    id: id.trim(),
    name: name.trim(),
    isEmployee: isEmployee,
  );

  /// Throws [ApiException] with `statusCode == 409` while any account still
  /// points at this department, which the screen shows as a banner.
  Future<String> delete(String id) => _api.deleteDepartment(id.trim());
}
