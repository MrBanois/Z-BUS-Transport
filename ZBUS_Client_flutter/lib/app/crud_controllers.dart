import '../presentation/shared/permissions.dart';
import 'crud_controller.dart';
import '../data/department_repository.dart';
import '../data/position_repository.dart';
import '../data/user_admin_repository.dart';

// Field keys shared by three places that must not drift: the server's
// errors.field_error calls, the UiFieldSpec keys in the dialogs, and the
// controllers' drafts. A rejection naming one of these renders under that input;
// anything else becomes a banner.
const String kNameField = 'name';
const String kEmployeeField = 'employee';
const String kPermissionsField = 'permissions';

const String kFirstNameField = 'firstName';
const String kLastNameField = 'lastName';
const String kEmailField = 'email';
const String kDepartmentField = 'department';
const String kPositionField = 'position';
const String kSalaryField = 'salary';
const String kPasswordField = 'password';

/// Mirrors `columns.MAX_REFERENCE_NAME_LENGTH`: DEPARTMENT.NAME and
/// POSITION.NAME are both VARCHAR2(20).
const int kMaxReferenceNameLength = 20;

/// Mirrors `columns.MAX_NAME_LENGTH`: USER.F_NAME and USER.L_NAME.
const int kMaxNameLength = 20;

/// Mirrors `columns.MAX_EMAIL_LENGTH`.
const int kMaxEmailLength = 100;

/// Mirrors `columns.MIN_PASSWORD_LENGTH`.
const int kMinPasswordLength = 6;

/// Mirrors `columns.MAX_SALARY`: USER.SALARY is number(8,2), so 999999.99 is the
/// largest value it can hold.
const double kMaxSalary = 999999.99;

/// Nothing granted. A new position starts here rather than fully granted, so a
/// mistake in the other direction costs screens nobody meant to hand out.
const Set<String> kBlankPermissionSet = <String>{};

/// Deliberately permissive: one @, no spaces, a dotted domain. Matches the
/// server's own rule so the form never rejects an address the server would have
/// accepted, and never accepts one it would have rejected.
final RegExp kEmailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Encode whatever a dialog left in the permissions draft field.
///
/// Anything that is not a set of screen names encodes to all-deny, so a draft
/// that was built wrongly produces a position with no screens rather than one
/// with all of them.
String maskOf(Object? value) =>
    permissionSetToMask(value is Set<String> ? value : const <String>{});

String _text(Object? value) => '${value ?? ''}'.trim();

/// How a name is checked, shared by DEPARTMENT.NAME and POSITION.NAME.
Map<String, String> _validateReferenceName(
  Map<String, Object?> draft,
  String noun,
) {
  final name = _text(draft[kNameField]);
  if (name.isEmpty) {
    return {kNameField: '$noun name cannot be empty'};
  }
  if (name.length > kMaxReferenceNameLength) {
    return {
      kNameField:
          '$noun name cannot exceed $kMaxReferenceNameLength characters',
    };
  }
  return const {};
}

// =============================================================================
// Departments
// =============================================================================

/// Manage departments.
class DepartmentController extends CrudController<DepartmentRecord> {
  DepartmentController({DepartmentRepository? repository})
    : _repository = repository ?? DepartmentRepository();

  final DepartmentRepository _repository;

  DepartmentRepository get repository => _repository;

  @override
  Future<List<DepartmentRecord>> fetch() => _repository.all();

  @override
  String idOf(DepartmentRecord row) => row.id;

  @override
  String labelOf(DepartmentRecord row) => row.name;

  @override
  String searchTextOf(DepartmentRecord row) => '${row.id} ${row.name}';

  @override
  Set<String> get fieldKeys => const {kNameField, kEmployeeField};

  @override
  Map<String, Object?> blankDraft() => const {kNameField: ''};

  @override
  Map<String, Object?> draftOf(DepartmentRecord row) => {
    kNameField: row.name,
    kEmployeeField: row.isEmployee,
  };

  @override
  Map<String, String> validate(Map<String, Object?> draft) =>
      _validateReferenceName(draft, 'Department');

  @override
  Future<String> persist(Map<String, Object?> draft, String? id) {
    final name = _text(draft[kNameField]);
    // Absent means staff, matching the server's default. Read as "not false"
    // rather than "== true" so a missing key cannot silently create a
    // passenger-facing department.
    final isEmployee = draft[kEmployeeField] != false;
    return id == null
        ? _repository.create(name: name, isEmployee: isEmployee)
        : _repository.update(id: id, name: name, isEmployee: isEmployee);
  }

  @override
  Future<void> remove(String id) => _repository.delete(id);
}

// =============================================================================
// Positions
// =============================================================================

/// Manage positions, including the permission mask the editor writes.
class PositionController extends CrudController<PositionRecord> {
  PositionController({PositionRepository? repository})
    : _repository = repository ?? PositionRepository();

  final PositionRepository _repository;

  PositionRepository get repository => _repository;

  @override
  Future<List<PositionRecord>> fetch() => _repository.all();

  @override
  String idOf(PositionRecord row) => row.id;

  @override
  String labelOf(PositionRecord row) => row.name;

  @override
  String searchTextOf(PositionRecord row) => '${row.id} ${row.name}';

  @override
  Set<String> get fieldKeys => const {kNameField, kPermissionsField, kEmployeeField};

  @override
  Map<String, Object?> blankDraft() => const {
    kNameField: '',
    // A set of screen names, not a mask string: the editor works in screens, and
    // encoding is this layer's job. See maskOf.
    kPermissionsField: kBlankPermissionSet,
    kEmployeeField: true,
  };

  @override
  Map<String, Object?> draftOf(PositionRecord row) => {
    kNameField: row.name,
    kPermissionsField: row.grantedScreens,
    kEmployeeField: row.isEmployee,
  };

  @override
  Map<String, String> validate(Map<String, Object?> draft) =>
      _validateReferenceName(draft, 'Position');

  @override
  Future<String> persist(Map<String, Object?> draft, String? id) {
    final name = _text(draft[kNameField]);
    final isEmployee = draft[kEmployeeField] != false;
    return id == null
        ? _repository.create(
            name: name,
            permissions: maskOf(draft[kPermissionsField]),
            isEmployee: isEmployee,
          )
        : _repository.update(
            id: id,
            name: name,
            permissions: maskOf(draft[kPermissionsField]),
            isEmployee: isEmployee,
          );
  }

  @override
  Future<void> remove(String id) => _repository.delete(id);
}

// =============================================================================
// Accounts
// =============================================================================

/// Manage users, and manage employees.
///
/// The employee screen is the same controller with [staffOnly] set rather than a
/// subclass with its own rules, so the two cannot disagree about validation,
/// passwords or the ISEMP default.
class UserController extends CrudController<ManagedUser> {
  UserController({UserAdminRepository? repository, this.staffOnly = false})
    : _repository = repository ?? UserAdminRepository();

  final UserAdminRepository _repository;

  /// When true the list is narrowed to ISEMP = 'T'.
  ///
  /// The narrowing happens over the one `/api/user` response the screen already
  /// has, not in a second request: there is no employee-specific endpoint, and
  /// adding one to save a filter the client can already apply would be a new
  /// contract for no behaviour. The consequence is that this flag controls what
  /// the list shows, not what an attacker could fetch.
  final bool staffOnly;

  UserAdminRepository get repository => _repository;

  /// Whether an account created here is staff.
  ///
  /// True on the employee screen, because its title says staff and offering to
  /// create a passenger on it would contradict that. False on the user screen,
  /// which manages the whole table.
  bool get createsStaff => staffOnly;

  @override
  Future<List<ManagedUser>> fetch() async {
    final all = await _repository.all();
    if (!staffOnly) return all;
    return [for (final row in all) if (row.isEmployee) row];
  }

  @override
  String idOf(ManagedUser row) => row.id;

  @override
  String labelOf(ManagedUser row) => row.fullName;

  @override
  String searchTextOf(ManagedUser row) =>
      '${row.id} ${row.firstName} ${row.lastName} ${row.email}';

  @override
  Set<String> get fieldKeys => const {
    kFirstNameField,
    kLastNameField,
    kEmailField,
    kDepartmentField,
    kPositionField,
    kSalaryField,
    kPasswordField,
  };

  @override
  Map<String, Object?> blankDraft() => {
    kFirstNameField: '',
    kLastNameField: '',
    kEmailField: '',
    kDepartmentField: '',
    kPositionField: '',
    kEmployeeField: createsStaff,
    kSalaryField: 0.0,
    kPasswordField: '',
  };

  @override
  Map<String, Object?> draftOf(ManagedUser row) => {
    kFirstNameField: row.firstName,
    kLastNameField: row.lastName,
    kEmailField: row.email,
    kDepartmentField: row.departmentId,
    kPositionField: row.positionId,
    kEmployeeField: row.isEmployee,
    kSalaryField: row.salary,
    // Never pre-filled. There is no stored value to show even if the server sent
    // one, and an empty box here is the instruction "leave the credential
    // alone" rather than a blank to be filled in.
    kPasswordField: '',
  };

  @override
  void set(String field, Object? value) {
    // Un-ticking staff is the one edit that invalidates other fields rather than
    // changing one, so it is applied as a single change to the draft. Doing it as
    // a sequence would let the dialog render a staff account carrying a salary
    // that no passenger is allowed to have.
    if (field == kEmployeeField && value == false) {
      patch(const {
        kSalaryField: 0.0,
        // Cleared rather than disabled, because the reference lists are not this
        // controller's to judge and it cannot tell a staff row from a passenger
        // one. The server refuses a passenger assigned to a staff department or
        // position, so leaving the old value would save a row that always fails;
        // blanking it asks for a fresh choice from the narrowed list.
        kDepartmentField: '',
        kPositionField: '',
      });
    }
    super.set(field, value);
  }

  @override
  Map<String, String> validate(Map<String, Object?> draft) {
    final problems = <String, String>{};

    final first = _text(draft[kFirstNameField]);
    if (first.isEmpty) {
      problems[kFirstNameField] = 'First name is required';
    } else if (first.length > kMaxNameLength) {
      problems[kFirstNameField] =
          'First name cannot exceed $kMaxNameLength characters';
    }

    final last = _text(draft[kLastNameField]);
    if (last.isEmpty) {
      problems[kLastNameField] = 'Last name is required';
    } else if (last.length > kMaxNameLength) {
      problems[kLastNameField] =
          'Last name cannot exceed $kMaxNameLength characters';
    }

    final email = _text(draft[kEmailField]);
    if (email.isEmpty) {
      problems[kEmailField] = 'Email is required';
    } else if (email.length > kMaxEmailLength) {
      problems[kEmailField] =
          'Email cannot exceed $kMaxEmailLength characters';
    } else if (!kEmailPattern.hasMatch(email)) {
      problems[kEmailField] = 'Email address is not valid';
    }

    if (_text(draft[kDepartmentField]).isEmpty) {
      problems[kDepartmentField] = 'Choose a department';
    }
    if (_text(draft[kPositionField]).isEmpty) {
      problems[kPositionField] = 'Choose a position';
    }

    final salary = draft[kSalaryField];
    if (salary is! num || salary.isNaN || salary < 0 || salary > kMaxSalary) {
      problems[kSalaryField] =
          'Salary must be a number no greater than ${kMaxSalary.toStringAsFixed(2)}';
    }

    // A password is required to create and optional to edit, so this reads the
    // controller's own mode rather than the draft: both start empty, and only one
    // of those empties is an omission.
    final password = _text(draft[kPasswordField]);
    if (editing) {
      if (password.isNotEmpty && password.length < kMinPasswordLength) {
        problems[kPasswordField] =
            'Password must be at least $kMinPasswordLength characters';
      }
    } else if (password.isEmpty) {
      problems[kPasswordField] = 'Password is required';
    } else if (password.length < kMinPasswordLength) {
      problems[kPasswordField] =
          'Password must be at least $kMinPasswordLength characters';
    }

    return problems;
  }

  @override
  Future<String> persist(Map<String, Object?> draft, String? id) {
    // An empty box is dropped by the repository, which on update means "leave the
    // stored hash alone". Sending an explicit null would have meant "reset".
    // Create cannot reach here empty: validate rejects it first.
    final password = _text(draft[kPasswordField]);
    final salary = draft[kSalaryField] is num
        ? (draft[kSalaryField] as num).toDouble()
        : 0.0;

    if (id == null) {
      return _repository.create(
        firstName: _text(draft[kFirstNameField]),
        lastName: _text(draft[kLastNameField]),
        email: _text(draft[kEmailField]),
        department: _text(draft[kDepartmentField]),
        position: _text(draft[kPositionField]),
        isEmployee: draft[kEmployeeField] != false,
        salary: salary,
        password: password,
      );
    }
    return _repository.update(
      id: id,
      firstName: _text(draft[kFirstNameField]),
      lastName: _text(draft[kLastNameField]),
      email: _text(draft[kEmailField]),
      department: _text(draft[kDepartmentField]),
      position: _text(draft[kPositionField]),
      isEmployee: draft[kEmployeeField] != false,
      salary: salary,
      password: password,
    );
  }

  @override
  Future<void> remove(String id) => _repository.delete(id);
}

/// Manage employees. Identical to [UserController] narrowed to staff.
class EmployeeController extends UserController {
  EmployeeController({super.repository}) : super(staffOnly: true);
}
