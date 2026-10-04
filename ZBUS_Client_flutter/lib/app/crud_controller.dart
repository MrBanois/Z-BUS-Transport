import 'package:flutter/foundation.dart';

import '../data/api_client.dart';

/// How a list screen is currently doing.
enum CrudStage {
  /// Nothing has been requested yet.
  idle,

  /// The first load is in flight. No rows are shown, because showing an empty
  /// table during the first load reads as "there are no records".
  loading,

  /// Rows are shown. A refresh in flight leaves them visible.
  ready,

  /// The list could not be loaded, and there is nothing to show.
  failed,
}

/// Everything the four management screens do, once.
///
/// Departments, positions, users and employees are the same shape of work: load a
/// list, filter it as the user types, open a dialog to create or edit, save,
/// delete. Only the fields differ. Keeping that shape in one base class means the
/// loading, failure, filtering, re-entrancy and error-routing rules are written
/// and tested once instead of four times, and the four screens cannot drift
/// apart on any of them.
///
/// Subclasses supply the entity: how to fetch it, what a blank draft looks like,
/// what a row becomes when edited, what is invalid, and how to persist and remove
/// it. Everything else lives here.
abstract class CrudController<T> extends ChangeNotifier {
  CrudController();

  // ===========================================================================
  // Entity contract
  // ===========================================================================

  /// Load every row. Throws [ApiException] on failure.
  Future<List<T>> fetch();

  /// The id used as the route parameter for writes. Must be stable and unique.
  String idOf(T row);

  /// What to display for a row in a dialog title or a confirm prompt.
  String labelOf(T row);

  /// The searchable text, lowercased by this class.
  String searchTextOf(T row);

  /// Field keys this entity's dialog uses. Used to decide whether a server
  /// rejection can be shown beside an input or has to become a banner.
  Set<String> get fieldKeys;

  /// The values a create dialog starts with.
  Map<String, Object?> blankDraft();

  /// The values an edit dialog starts with.
  Map<String, Object?> draftOf(T row);

  /// Field-keyed messages for anything wrong with [draft]. Empty means valid.
  Map<String, String> validate(Map<String, Object?> draft);

  /// Create or update, depending on [id] being null. Returns the server's
  /// confirmation, usually the affected id.
  Future<String> persist(Map<String, Object?> draft, String? id);

  /// Remove a row. Throws [ApiException] on failure, notably 409 when the row is
  /// still referenced.
  Future<void> remove(String id);

  // ===========================================================================
  // List state
  // ===========================================================================

  CrudStage _stage = CrudStage.idle;
  List<T> _rows = const [];
  String _query = '';
  String? _error;

  CrudStage get stage => _stage;

  /// The unfiltered rows.
  List<T> get rows => _rows;

  String get query => _query;

  /// A message to show above the table, from the last failed list or write.
  String? get error => _error;

  /// A message to show above the table, from the last successful write.
  String? get notice => _notice;

  String? _notice;

  /// The rows the table should show: [rows] narrowed by [query].
  ///
  /// Filtering is here rather than in the widget so the count in the table
  /// footer and the rows themselves can never disagree. An empty query shows
  /// everything, including an empty table, rather than reporting no matches.
  List<T> get visible {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return _rows;
    return [
      for (final row in _rows)
        if (searchTextOf(row).toLowerCase().contains(needle)) row,
    ];
  }

  /// Whether the table should say "no records" or "no matches", which are
  /// different statements and both wrong at the same time if chosen by count
  /// alone.
  String get emptyLabel =>
      _query.trim().isEmpty ? 'No records yet' : 'No records match your search';

  // ===========================================================================
  // Dialog state
  // ===========================================================================

  bool _open = false;
  String? _editingId;
  Map<String, Object?> _draft = const {};
  Map<String, String> _fieldErrors = const {};
  bool _saving = false;

  /// Whether a create or edit dialog is open.
  bool get open => _open;

  /// Whether the dialog edits an existing row, or creates a new one.
  bool get editing => _editingId != null;

  /// The id being edited, or null when creating.
  String? get editingId => _editingId;

  Map<String, Object?> get draft => _draft;

  Map<String, String> get fieldErrors => _fieldErrors;

  /// True while a save or delete is in flight. Disables the dialog's buttons so
  /// a double tap cannot send the request twice.
  bool get saving => _saving;

  // ===========================================================================
  // List actions
  // ===========================================================================

  /// Load the list, unless a load is already running.
  ///
  /// Re-entrancy matters here for the same reason it does on the account
  /// screen: a host schedules this from a lifecycle callback, a retry button
  /// calls it again, and a refresh can land while the first is still open.
  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _stage == CrudStage.ready) return;
    _loading = true;
    if (_rows.isEmpty) _stage = CrudStage.loading;
    notifyListeners();
    try {
      _rows = await fetch();
      _stage = CrudStage.ready;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      _stage = CrudStage.failed;
    } catch (_) {
      _error = 'Something went wrong loading this list.';
      _stage = CrudStage.failed;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  bool _loading = false;

  /// Refresh while keeping the current rows visible. Used after a write, where
  /// blanking the table would be a worse answer than showing stale data for a
  /// moment.
  Future<void> refresh() => load(force: true);

  void search(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  /// Clear both the search text and any banner.
  void dismissMessages() {
    if (_error == null && _notice == null) return;
    _error = null;
    _notice = null;
    notifyListeners();
  }

  // ===========================================================================
  // Dialog actions
  // ===========================================================================

  void openCreate() {
    _open = true;
    _editingId = null;
    _draft = blankDraft();
    _fieldErrors = const {};
    _error = null;
    notifyListeners();
  }

  void openEdit(T row) {
    _open = true;
    _editingId = idOf(row);
    _draft = draftOf(row);
    _fieldErrors = const {};
    _error = null;
    notifyListeners();
  }

  /// Close without saving. A dialog dismissed this way keeps whatever the
  /// server has, which is the only safe default: the draft is unsaved input.
  void close() {
    if (!_open) return;
    _open = false;
    _editingId = null;
    _draft = const {};
    _fieldErrors = const {};
    _saving = false;
    notifyListeners();
  }

  /// Record an edit to one field.
  ///
  /// Clearing that field's error as the user types is deliberate: leaving a
  /// stale rejection under an input the user is actively correcting is worse
  /// than waiting for the next save to report it again. An edit that changes
  /// nothing is ignored, so a text field re-reporting the same characters on
  /// every keystroke does not rebuild the dialog.
  void set(String field, Object? value) {
    if (_draft[field] == value) return;
    _draft = {..._draft, field: value};
    if (_fieldErrors.containsKey(field)) {
      _fieldErrors = Map.of(_fieldErrors)..remove(field);
    }
    notifyListeners();
  }

  /// Replace several fields at once, for a control that edits them together such
  /// as the permission mask editor.
  ///
  /// Errors for the touched fields are cleared, because a control that moves
  /// several values has usually moved them in response to the same correction.
  void patch(Map<String, Object?> changes) {
    _draft = {..._draft, ...changes};
    final stale = _fieldErrors.keys.where(changes.containsKey).toSet();
    if (stale.isNotEmpty) {
      _fieldErrors = Map.of(_fieldErrors)
        ..removeWhere((field, _) => stale.contains(field));
    }
    notifyListeners();
  }

  /// Validate and persist the open dialog, then close it and refresh the list.
  ///
  /// Returns whether anything was written. A rejected draft returns false with
  /// the reason in [fieldErrors] and the dialog still open; a transport failure
  /// returns false with the reason in [error] and the dialog still open, so the
  /// typed values are not lost to a dropped connection.
  Future<bool> save() async {
    if (_saving || !_open) return false;

    final problems = validate(_draft);
    if (problems.isNotEmpty) {
      _fieldErrors = problems;
      notifyListeners();
      return false;
    }

    _saving = true;
    _fieldErrors = const {};
    _error = null;
    notifyListeners();

    try {
      final saved = await persist(_draft, _editingId);
      final created = _editingId == null;
      _open = false;
      _editingId = null;
      _draft = const {};
      _notice = created ? 'Created $saved.' : 'Saved $saved.';
    } on ApiException catch (e) {
      _error = e.message;
      // A rejection that names a field this dialog renders goes under that
      // input. One that names nothing renderable, or none at all, stays a
      // banner: it is better to show a message beside no input than to drop it.
      if (e.field != null && fieldKeys.contains(e.field)) {
        _fieldErrors = {e.field!: e.message};
        _error = null;
      }
    } catch (_) {
      _error = 'Something went wrong saving. Nothing was changed.';
    } finally {
      _saving = false;
      notifyListeners();
    }

    if (!_open) await refresh();
    return !_open;
  }

  /// Delete a row after confirmation, then refresh.
  ///
  /// Confirmation is the caller's business, not this class's: it is a dialog,
  /// and this layer does not build widgets.
  Future<bool> delete(T row) async {
    final id = idOf(row);
    if (_saving) return false;

    _saving = true;
    _error = null;
    notifyListeners();

    var deleted = false;
    try {
      await remove(id);
      deleted = true;
      _notice = 'Deleted ${labelOf(row)}.';
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong deleting. Nothing was removed.';
    } finally {
      _saving = false;
      notifyListeners();
    }

    if (deleted) await refresh();
    return deleted;
  }
}
