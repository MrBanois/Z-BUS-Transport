import '../presentation/shared/permissions.dart';
import 'api_client.dart';
import 'choice_option.dart';

/// A row of POSITION, from `GET /api/position`.
class PositionRecord {
  const PositionRecord({
    required this.id,
    required this.name,
    required this.permission,
    required this.isEmployee,
  });

  final String id;
  final String name;

  /// The stored 16 character '0'/'1' mask, exactly as the server sent it.
  final String permission;

  /// ISEMP. False marks a position that public registration may select.
  final bool isEmployee;

  /// The screens this position unlocks, by name.
  ///
  /// A malformed mask decodes to nothing rather than throwing: one bad row
  /// should cost that row its permissions, not break the list it appears in.
  Set<String> get grantedScreens => permissionMaskToSet(permission);

  /// The mask rebuilt in canonical bit order from [grantedScreens].
  ///
  /// Round tripping through this rather than echoing [permission] means a save
  /// can never write a mask whose bit order disagrees with [kPermissionOrder],
  /// and a malformed stored value is repaired to all-deny on the way out instead
  /// of being preserved.
  String get permissions => permissionSetToMask(grantedScreens);

  static String text(Object? value) => '${value ?? ''}'.trim();

  factory PositionRecord.fromJson(Map<String, dynamic> json) => PositionRecord(
    id: text(json['id']),
    name: text(json['name']),
    permission: text(json['permission']),
    isEmployee: json['isemp'] == true,
  );

  ChoiceOption get option => ChoiceOption(id: id, name: name);
}

/// Reads and writes POSITION, including the permission mask the editor writes.
class PositionRepository {
  PositionRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  ApiClient get api => _api;

  Future<List<PositionRecord>> all() async => [
    for (final row in await _api.positions()) PositionRecord.fromJson(row),
  ];

  /// [permissions] must be a valid 16 character mask; the server rejects
  /// anything else rather than storing a mask that means something other than
  /// what the editor showed.
  Future<String> create({
    required String name,
    required String permissions,
    required bool isEmployee,
  }) => _api.createPosition(
    name: name.trim(),
    permissions: permissions.trim(),
    isEmployee: isEmployee,
  );

  /// A full replacement. The caller must resend the mask it already had; the
  /// server has no partial update, so omitting `permissions` is a 422 rather
  /// than a silent reset to no screens.
  Future<String> update({
    required String id,
    required String name,
    required String permissions,
    required bool isEmployee,
  }) => _api.updatePosition(
    id: id.trim(),
    name: name.trim(),
    permissions: permissions.trim(),
    isEmployee: isEmployee,
  );

  /// Throws [ApiException] with `statusCode == 409` while any account still
  /// holds this position.
  Future<String> delete(String id) => _api.deletePosition(id.trim());
}
