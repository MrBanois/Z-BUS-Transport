import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/choice_option.dart';
import '../data/user_repository.dart';

/// What the account screen is currently doing.
enum ProfileStage {
  /// Nothing loaded yet.
  idle,

  /// The record is being fetched. The screen shows a placeholder rather than an
  /// empty form, so a loading screen cannot be mistaken for a nameless member.
  loading,

  /// Loaded, and either unchanged or edited.
  ready,

  /// The load failed. [AccountController.error] explains why.
  failed,

  /// A save is in flight. The form disables itself so a double tap cannot send
  /// the same update twice.
  saving,
}

/// Owns the My account screen's state.
///
/// The screen is a controlled widget with no network logic and no opinion about
/// what may be edited. This decides that, from the account's stored `ISEMP` flag
/// and from what the server said about the last attempt.
///
/// Changing position changes which screens the member can open, but the mask is
/// only decoded at sign-in, so a save that moves the position reports that a
/// re-login is needed rather than leaving the navigation quietly stale.
class AccountController extends ChangeNotifier {
  AccountController({UserRepository? repository})
    : _repository = repository ?? UserRepository();

  final UserRepository _repository;

  UserRepository get repository => _repository;

  ProfileStage _stage = ProfileStage.idle;
  ProfileStage get stage => _stage;

  bool get loading => _stage == ProfileStage.loading;

  bool get saving => _stage == ProfileStage.saving;

  /// True while a load or a save is in flight, for controls that must be inert
  /// during both.
  bool get busy => loading || saving;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  /// Whether the member is staff, in which case the assignment fields are
  /// read-only. The server refuses such a change independently.
  bool get isEmployee => _profile?.isEmployee ?? false;

  /// Uncommitted edits, keyed by the field names the screen renders.
  ///
  /// Kept apart from [_profile] so a rejected save can be corrected and retried
  /// without a reload throwing away what was typed.
  final Map<String, Object?> _values = {};
  Map<String, Object?> get values => Map<String, Object?>.unmodifiable(_values);

  Map<String, String> _fieldErrors = const {};
  Map<String, String> get fieldErrors => _fieldErrors;

  String? _error;
  String? get error => _error;

  /// A result that should persist until the next edit, such as a successful save.
  String? _notice;
  String? get notice => _notice;

  /// Set by a successful save that moved the position, so the shell can tell the
  /// member their screens will differ after the next sign-in.
  bool _permissionsChanged = false;
  bool get permissionsChanged => _permissionsChanged;

  /// The passenger-facing assignment lists, empty for an employee whose fields
  /// never enable.
  List<ChoiceOption> _departments = const [];
  List<ChoiceOption> _positions = const [];
  List<ChoiceOption> get departments => _departments;
  List<ChoiceOption> get positions => _positions;

  bool _optionsLoading = false;
  bool get optionsLoading => _optionsLoading;

  /// The id currently held, so a rebuild does not re-fetch it.
  String? _loadedFor;
  String? get loadedFor => _loadedFor;

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  /// Fetch [userId]'s profile, plus the assignment dropdowns if the member is a
  /// passenger.
  ///
  /// Safe to call on every rebuild: a repeat for the id already held does
  /// nothing unless [force] is set.
  Future<void> load(String userId, {bool force = false}) async {
    if (busy) return;
    if (!force && _profile != null && _loadedFor == userId) return;
    await _fetch(userId);
  }

  /// The read, with no guard, so [save] can refresh after its own write.
  Future<void> _fetch(String userId) async {
    _stage = ProfileStage.loading;
    _error = null;
    _notice = null;
    _permissionsChanged = false;
    notifyListeners();

    UserProfile profile;
    try {
      profile = await _repository.profile(userId);
    } on ApiException catch (e) {
      _stage = ProfileStage.failed;
      _error = e.message;
      notifyListeners();
      return;
    }

    _profile = profile;
    _loadedFor = profile.id;
    _resetValues();
    _fieldErrors = const {};
    _stage = ProfileStage.ready;
    notifyListeners();

    // Only a passenger needs these. An employee sees the assignment as read-only
    // text, so fetching the lists would be a round trip for controls that never
    // enable.
    if (profile.isEmployee) {
      _departments = const [];
      _positions = const [];
      return;
    }

    _optionsLoading = true;
    notifyListeners();
    try {
      final options = await _repository.passengerAssignmentOptions();
      _departments = options.departments;
      _positions = options.positions;
      _error = null;
    } on ApiException catch (e) {
      // A banner, not a blocked form: the member can still edit their name, and
      // the server re-validates whatever is submitted.
      _error = e.message;
    } finally {
      _optionsLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Edit
  // ---------------------------------------------------------------------------

  /// Record an edit. Ignored while a request is in flight, so a save cannot race
  /// a keystroke.
  void set(String field, Object? value) {
    if (busy) return;
    // An employee's assignment is read-only. The screen already disables the
    // dropdowns, and the server rejects such a change, but the controller should
    // not hold the only copy of that rule.
    if (isEmployee && (field == 'department' || field == 'position')) return;

    _values[field] = value;
    if (_fieldErrors.containsKey(field)) {
      _fieldErrors = Map<String, String>.of(_fieldErrors)..remove(field);
    }
    // An old result must not sit over freshly edited fields.
    _notice = null;
    notifyListeners();
  }

  /// Discard edits and show the stored values again.
  void revert() {
    if (_profile == null || busy) return;
    _resetValues();
    _fieldErrors = const {};
    _notice = null;
    notifyListeners();
  }

  /// Whether the form differs from what is stored, so the save button only
  /// enables when there is something to send.
  bool get dirty {
    final profile = _profile;
    if (profile == null) return false;
    return text(_values['firstName']) != profile.firstName ||
        text(_values['lastName']) != profile.lastName ||
        text(_values['department']) != profile.departmentId ||
        text(_values['position']) != profile.positionId;
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  /// Persist the editable subset, then re-read the record.
  ///
  /// Returns false without contacting the server when nothing has changed or
  /// when local validation rejects the form.
  Future<bool> save() async {
    final profile = _profile;
    if (profile == null || busy || !dirty) return false;

    final errors = <String, String>{};
    final firstName = text(_values['firstName']);
    final lastName = text(_values['lastName']);
    // Mirrors MAX_NAME_LENGTH in Production/Server/columns.py, so an over-long
    // name is caught here rather than as ORA-12899 from Oracle.
    if (firstName.isEmpty) {
      errors['firstName'] = 'Required';
    } else if (firstName.length > 20) {
      errors['firstName'] = 'At most 20 characters';
    }
    if (lastName.isEmpty) {
      errors['lastName'] = 'Required';
    } else if (lastName.length > 20) {
      errors['lastName'] = 'At most 20 characters';
    }
    if (!isEmployee) {
      if (text(_values['department']).isEmpty) {
        errors['department'] = 'Choose a department';
      }
      if (text(_values['position']).isEmpty) {
        errors['position'] = 'Choose a position';
      }
    }
    if (errors.isNotEmpty) {
      _fieldErrors = errors;
      notifyListeners();
      return false;
    }

    final department = isEmployee ? null : text(_values['department']);
    final position = isEmployee ? null : text(_values['position']);
    final movedPosition = position != null && position != profile.positionId;

    _stage = ProfileStage.saving;
    _error = null;
    _notice = null;
    notifyListeners();

    try {
      await _repository.save(
        userId: profile.id,
        firstName: firstName,
        lastName: lastName,
        department: department,
        position: position,
      );
    } on ApiException catch (e) {
      _stage = ProfileStage.ready;
      // The server names the control it rejected. A name this form does not
      // render is treated as a banner rather than dropped: a message with
      // nowhere to go is worse than one shown above the form.
      final field = e.field;
      final targeted = field != null && _values.containsKey(field);
      _error = targeted ? null : e.message;
      _fieldErrors = targeted ? {field: e.message} : const {};
      notifyListeners();
      return false;
    }

    // Re-read rather than trusting what was sent: the server trims, and the
    // reload is what proves the change landed.
    await _fetch(profile.id);

    _permissionsChanged = movedPosition;
    _notice = movedPosition
        ? 'Profile saved. Your screens come from your position, so sign out and '
              'back in to see the updated set.'
        : 'Profile saved.';
    notifyListeners();
    return true;
  }

  /// Forget everything, for when the session ends.
  void reset() {
    _profile = null;
    _loadedFor = null;
    _stage = ProfileStage.idle;
    _error = null;
    _notice = null;
    _fieldErrors = const {};
    _departments = const [];
    _positions = const [];
    _permissionsChanged = false;
    _values.clear();
    notifyListeners();
  }

  void _resetValues() {
    final profile = _profile;
    if (profile == null) return;
    _values
      ..clear()
      ..addAll({
        'firstName': profile.firstName,
        'lastName': profile.lastName,
        'department': profile.departmentId,
        'position': profile.positionId,
      });
  }

  static String text(Object? value) => '${value ?? ''}'.trim();
}
