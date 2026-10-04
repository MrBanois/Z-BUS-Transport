import 'package:flutter/material.dart';

import '../data/department_repository.dart';
import '../data/position_repository.dart';
import '../data/user_admin_repository.dart';
import '../presentation/features/department_management/department_management_page.dart';
import '../presentation/features/department_management/widgets/department_form.dart';
import '../presentation/features/employee_management/employee_management_page.dart';
import '../presentation/features/employee_management/widgets/employee_form.dart';
import '../presentation/features/position_management/position_management_page.dart';
import '../presentation/features/position_management/widgets/position_form.dart';
import '../presentation/features/user_management/user_management_page.dart';
import '../presentation/features/user_management/widgets/user_form.dart';
import '../presentation/shared/account_copy.dart';
import '../presentation/shared/design_system.dart';
import '../presentation/shared/permissions.dart';
import '../presentation/shared/ui_fields.dart';
import '../presentation/shared/ui_table.dart';
import 'crud_controller.dart';
import 'crud_controllers.dart';

/// Base for the four management screens, so they are recognisably one family.
abstract class CrudHostWidget<T extends Object> extends StatefulWidget {
  const CrudHostWidget({super.key});
}

/// Ask before deleting, and return whether the caller may go ahead.
///
/// A delete cannot be undone, and the reference tables are protected by the
/// server rather than by this dialog, so it has to say what will happen when the
/// server refuses.
Future<bool> confirmDelete(BuildContext context, String label) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => ZDialog(
      title: 'Delete $label',
      actions: [
        ZButton(
          'Cancel',
          secondary: true,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        ZButton(
          'Delete',
          icon: Icons.delete_outline,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
      child: const Text(
        'This cannot be undone. If anything still refers to this record the '
        'server will refuse and nothing will be removed.',
        style: TextStyle(color: ZColors.muted, fontSize: 13, height: 1.5),
      ),
    ),
  );
  return confirmed == true;
}

/// The permission selection, decoded for [PermissionEditor].
///
/// A draft that is not a set of screen names renders as nothing granted, which is
/// the safe direction: a position showing no screens cannot be saved with screens
/// nobody picked.
Map<String, bool> permissionSelectionOf(Object? value) => value is Set<String>
    ? {for (final screen in kPermissionOrder) screen: value.contains(screen)}
    : const {};

/// A position's mask as the table shows it: the one screen granted when there is
/// one, otherwise a count, rather than sixteen characters.
String maskSummary(String? mask) {
  final granted = permissionMaskToSet(mask);
  if (granted.isEmpty) return 'No screens';
  if (granted.length == 1) return granted.first;
  return '${granted.length} screens';
}

/// The plumbing every management screen needs: the search box's controller, a
/// first load scheduled off the build, and rows built from the controller's
/// filtered view.
///
/// A mixin rather than a base class, because what differs between the four hosts
/// is the page and the dialog, which is exactly what a subclass would override
/// anyway; what is shared is small and always identical.
///
/// Declared with no `on` clause and its `State` members abstract, deliberately.
/// Constraining it to `State<CrudHostWidget<T>>` looks tidier but makes every
/// host inherit two instantiations of `State` — `State<DepartmentCrudHost>` from
/// the widget and `State<CrudHostWidget<DepartmentRecord>>` from the mixin — which
/// Dart rejects outright. Asking for `context`, `mounted` and `setState` instead
/// is satisfied by whichever `State` the host already has.
mixin CrudHostMixin<T extends Object> {
  /// Supplied by `State`.
  BuildContext get context;

  /// Supplied by `State`.
  bool get mounted;

  /// Supplied by `State`.
  void setState(VoidCallback fn);

  final TextEditingController search = TextEditingController();

  /// The reference lists behind the assignment dropdowns. Empty until
  /// [loadOptions] completes, which is why the account dialogs wait for it.
  List<DepartmentRecord> departments = const [];
  List<PositionRecord> positions = const [];
  bool optionsFailed = false;

  /// Schedule [work] after the current frame.
  ///
  /// Never call a controller's `load()` from `build`: its first
  /// `notifyListeners` would arrive while the framework is building this widget,
  /// which throws.
  void afterFrame(Future<void> Function() work) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) work();
    });
  }

  /// Follow a controller: rebind when it is swapped, and load once the swap has
  /// been rendered. [didUpdateWidget] owns the call, because only it knows the
  /// old controller.
  void followController(
    CrudController<T> controller,
    VoidCallback listener,
    Future<void> Function() bootstrap,
  ) {
    controller.addListener(listener);
    afterFrame(bootstrap);
  }

  /// The rows the table shows, each already carrying its edit and delete
  /// callbacks. Filtering is the controller's, never this method's.
  ///
  /// [openDialog] is the host's own opener rather than `controller.openEdit`,
  /// because filling in the draft and showing it are two different things: a
  /// row's edit button has to push a dialog, and calling the controller alone
  /// would set the draft with nothing on screen to edit it in.
  List<UiTableRow> buildRows(
    CrudController<T> controller,
    void Function(T row) openDialog,
    UiTableRow Function(
      T row,
      VoidCallback onEdit,
      Future<void> Function() onDelete,
    )
    toRow,
  ) => [
    for (final row in controller.visible)
      toRow(
        row,
        () => openDialog(row),
        () async {
          if (await confirmDelete(context, controller.labelOf(row))) {
            await controller.delete(row);
          }
        },
      ),
  ];

  /// Load the reference lists the account dropdowns need.
  ///
  /// Reported on the page rather than thrown: the account list is still worth
  /// showing, and only the dialog is unusable until this succeeds.
  Future<void> loadOptions({
    required DepartmentRepository departmentSource,
    required PositionRepository positionSource,
  }) async {
    try {
      final loadedDepartments = await departmentSource.all();
      final loadedPositions = await positionSource.all();
      if (!mounted) return;
      setState(() {
        departments = loadedDepartments;
        positions = loadedPositions;
        optionsFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => optionsFailed = true);
    }
  }

  /// The assignment dropdowns, with an explicit blank first so an unassigned
  /// draft does not silently preselect whichever row happens to sort first.
  ///
  /// A passenger is only offered passenger-facing references, because the server
  /// refuses any other combination: `_check_assignment` requires both rows to
  /// exist with ISEMP = 'F' when the account is not staff. Offering a staff
  /// department that is guaranteed to be rejected would be a choice that always
  /// fails, so the list is narrowed instead and the controller blanks the value
  /// when the account type is un-ticked.
  Map<String, List<UiOption>> assignmentOptions({required bool staff}) => {
    kDepartmentField: [
      const UiOption('', 'Not set'),
      for (final row in departments)
        if (staff || !row.isEmployee) UiOption(row.id, row.name),
    ],
    kPositionField: [
      const UiOption('', 'Not set'),
      for (final row in positions)
        if (staff || !row.isEmployee) UiOption(row.id, row.name),
    ],
  };

  /// The dialog's values: the draft, plus the read-only id when editing.
  ///
  /// The id is not part of the draft because it is not editable, and putting it in
  /// the draft would give the form a field the controller can never see change.
  Map<String, Object?> dialogValues(CrudController<T> controller) => {
    ...controller.draft,
    if (controller.editingId != null) 'id': controller.editingId,
  };

  /// Save, then close the dialog on success.
  ///
  /// Left open on failure, so nothing typed is lost to a rejected field or a
  /// dropped connection.
  Future<void> saveAndClose(
    CrudController<T> controller,
    BuildContext dialogContext,
  ) async {
    if (controller.saving) return;
    if (await controller.save() && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
  }

  /// Delete from inside a dialog, then close it.
  Future<void> deleteFromDialog(
    CrudController<T> controller,
    T row,
    BuildContext dialogContext,
  ) async {
    if (await confirmDelete(context, controller.labelOf(row))) {
      await controller.delete(row);
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
    }
  }

  void cancel(BuildContext dialogContext) => Navigator.of(dialogContext).pop();

  /// The record the open dialog is editing, or null when creating.
  ///
  /// Looked up by id rather than held, so it cannot go stale against a list that
  /// a refresh has since replaced.
  T? editingRowOf(CrudController<T> controller) {
    final id = controller.editingId;
    if (id == null) return null;
    for (final row in controller.rows) {
      if (controller.idOf(row) == id) return row;
    }
    return null;
  }

  /// Cancel / Save, with the save button disabled while a request is in flight
  /// and labelled for what the dialog is about to do.
  ///
  /// Shared by all four dialogs because a double submit is the same bug on every
  /// screen, and it costs a duplicate record when it happens.
  List<Widget> dialogActions(
    CrudController<T> controller,
    BuildContext dialogContext, {
    bool deleting = false,
  }) => [
    if (deleting)
      ZButton(
        'Delete',
        secondary: true,
        onPressed: controller.saving
            ? null
            : () {
                final row = editingRowOf(controller);
                if (row != null) {
                  deleteFromDialog(controller, row, dialogContext);
                }
              },
      ),
    ZButton(
      'Cancel',
      secondary: true,
      onPressed: controller.saving ? null : () => cancel(dialogContext),
    ),
    ZButton(
      controller.saving
          ? 'Saving'
          : (controller.editing ? 'Save' : 'Create'),
      onPressed: controller.saving
          ? null
          : () => saveAndClose(controller, dialogContext),
    ),
  ];
}

// =============================================================================
// Departments
// =============================================================================

class DepartmentCrudHost extends CrudHostWidget<DepartmentRecord> {
  const DepartmentCrudHost({super.key, required this.controller});

  final DepartmentController controller;

  @override
  State<DepartmentCrudHost> createState() => _DepartmentCrudHostState();
}

class _DepartmentCrudHostState extends State<DepartmentCrudHost>
    with CrudHostMixin<DepartmentRecord> {
  DepartmentController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    followController(_c, _onChanged, () => _c.load());
  }

  @override
  void didUpdateWidget(covariant DepartmentCrudHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onChanged);
    followController(_c, _onChanged, () => _c.load());
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    search.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openDialog([DepartmentRecord? row]) async {
    if (row == null) {
      _c.openCreate();
    } else {
      _c.openEdit(row);
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => ZDialog(
          title: row == null ? 'New department' : 'Edit ${row.name}',
          actions: dialogActions(_c, dialogContext, deleting: row != null),
          child: DepartmentForm(
            values: dialogValues(_c),
            errors: _c.fieldErrors,
            onChanged: _c.set,
            bare: true,
          ),
        ),
      ),
    );
    // Covers every way out of the dialog, including the system back button,
    // which bypasses the Cancel action above.
    _c.close();
  }

  @override
  Widget build(BuildContext context) => DepartmentManagementPage(
    rows: buildRows(_c, _openDialog, (row, onEdit, onDelete) => UiTableRow(
      cells: {'ID': row.id, 'Name': row.name},
      onEdit: onEdit,
      onDelete: () => onDelete(),
    )),
    searchController: search,
    onSearchChanged: _c.search,
    onAdd: () => _openDialog(),
    loading: _c.stage == CrudStage.loading,
    error: _c.error,
    notice: _c.notice,
    onRetry: () => afterFrame(() => _c.load(force: true)),
    onDismiss: _c.dismissMessages,
    emptyLabel: _c.emptyLabel,
  );
}

// =============================================================================
// Positions
// =============================================================================

class PositionCrudHost extends CrudHostWidget<PositionRecord> {
  const PositionCrudHost({super.key, required this.controller});

  final PositionController controller;

  @override
  State<PositionCrudHost> createState() => _PositionCrudHostState();
}

class _PositionCrudHostState extends State<PositionCrudHost>
    with CrudHostMixin<PositionRecord> {
  PositionController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    followController(_c, _onChanged, () => _c.load());
  }

  @override
  void didUpdateWidget(covariant PositionCrudHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onChanged);
    followController(_c, _onChanged, () => _c.load());
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    search.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Toggling one screen in the editor re-encodes the whole selection.
  ///
  /// The draft holds a set of screen names rather than a mask, so the editor and
  /// the controller never have to agree on a character order; `maskOf` produces
  /// the string only when the row is actually written.
  void _togglePermission(String screen, bool granted) {
    final current = _c.draft[kPermissionsField];
    final next = <String>{...?current is Set<String> ? current : null};
    if (granted) {
      next.add(screen);
    } else {
      next.remove(screen);
    }
    _c.patch({kPermissionsField: next});
  }

  Future<void> _openDialog([PositionRecord? row]) async {
    if (row == null) {
      _c.openCreate();
    } else {
      _c.openEdit(row);
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => ZDialog(
          title: row == null ? 'New position' : 'Edit ${row.name}',
          width: 520,
          actions: dialogActions(_c, dialogContext, deleting: row != null),
          child: PositionForm(
            values: dialogValues(_c),
            errors: _c.fieldErrors,
            permissions: permissionSelectionOf(_c.draft[kPermissionsField]),
            onPermissionChanged: _togglePermission,
            onChanged: _c.set,
            bare: true,
          ),
        ),
      ),
    );
    _c.close();
  }

  @override
  Widget build(BuildContext context) => PositionManagementPage(
    rows: buildRows(_c, _openDialog, (row, onEdit, onDelete) => UiTableRow(
      cells: {
        'ID': row.id,
        'Name': row.name,
        'Permissions': maskSummary(row.permission),
      },
      onEdit: onEdit,
      onDelete: () => onDelete(),
    )),
    searchController: search,
    onSearchChanged: _c.search,
    onAdd: () => _openDialog(),
    loading: _c.stage == CrudStage.loading,
    error: _c.error,
    notice: _c.notice,
    onRetry: () => afterFrame(() => _c.load(force: true)),
    onDismiss: _c.dismissMessages,
    emptyLabel: _c.emptyLabel,
  );
}

// =============================================================================
// Users and employees
// =============================================================================

/// Serves both account screens. [staffOnly] picks which page renders and which
/// default the form starts from; everything else is identical, because
/// `PUT /api/user/{id}` is one route either way and a form that differed between
/// the two screens could silently reset a column the other one owns.
class AccountCrudHost extends CrudHostWidget<ManagedUser> {
  const AccountCrudHost({
    super.key,
    required this.controller,
    required this.staffOnly,
  });

  final UserController controller;
  final bool staffOnly;

  @override
  State<AccountCrudHost> createState() => _AccountCrudHostState();
}

class _AccountCrudHostState extends State<AccountCrudHost>
    with CrudHostMixin<ManagedUser> {
  UserController get _c => widget.controller;

  bool get _staffOnly => widget.staffOnly;

  @override
  void initState() {
    super.initState();
    followController(_c, _onChanged, _bootstrap);
  }

  @override
  void didUpdateWidget(covariant AccountCrudHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onChanged);
    followController(_c, _onChanged, _bootstrap);
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    search.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// The list first, then the reference lists the dialogs need. Sequential rather
  /// than parallel so a failure in either is reported once, and so Add stays
  /// disabled until both have arrived.
  ///
  /// The reference repositories are built from the *account* repository's
  /// [ApiClient] rather than from their own defaults. Building fresh controllers
  /// here would reach the compiled-in base URL instead of the one this list is
  /// already talking to, so a build pointed at another server would show accounts
  /// from one host with departments from another.
  Future<void> _bootstrap() async {
    await _c.load();
    final api = _c.repository.api;
    await loadOptions(
      departmentSource: DepartmentRepository(api: api),
      positionSource: PositionRepository(api: api),
    );
  }

  /// Why the account form cannot be opened, and a way out of it.
  ///
  /// The pages treat a null `onAdd` as "nothing is wired yet" and open a static
  /// preview form, so the host must not pass null to mean "unavailable" — that
  /// would hand the user a Save button with nothing behind it. Instead Add stays
  /// enabled and says what is wrong.
  Future<void> _explainNoOptions() async {
    final reason =
        'Departments and positions could not be loaded, so the account form has '
        'no choices to offer.';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ZDialog(
        title: 'Account form unavailable',
        actions: [
          ZButton(
            'Cancel',
            secondary: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ZButton(
            'Retry',
            icon: Icons.refresh,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              afterFrame(_bootstrap);
            },
          ),
        ],
        child: Text(
          reason,
          style: const TextStyle(color: ZColors.muted, fontSize: 13, height: 1.5),
        ),
      ),
    );
  }

  Future<void> _openDialog([ManagedUser? row]) async {
    if (row == null) {
      _c.openCreate();
    } else {
      _c.openEdit(row);
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => ZDialog(
          title: row == null
              ? (_staffOnly ? 'New employee' : 'New user')
              : 'Edit ${row.fullName}',
          width: 520,
          actions: dialogActions(_c, dialogContext, deleting: row != null),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _accountFields(dialogValues(_c), _c.fieldErrors, _c.set),
                const ZGap(4),
                ZNotice(
                  _c.editing ? 'Editing an account' : 'Creating an account',
                  // An empty box means two different things per route, so the
                  // dialog says which one it is about to send.
                  _c.editing ? kPasswordKeptHint : kNewPasswordHint,
                  color: ZColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _c.close();
  }

  /// The two account forms share every field except the account type, so they are
  /// built here rather than duplicated per screen.
  ///
  /// `bare` because this host supplies the shell: the save action has to be
  /// disabled while the request is in flight, and the password notice has to sit
  /// below the fields.
  ///
  /// The option lists depend on the draft's account type, so this cannot be hoisted
  /// out of the dialog builder — it is a function of what is currently being typed.
  Widget _accountFields(
    Map<String, Object?> values,
    Map<String, String> errors,
    void Function(String, Object?) onChanged,
  ) {
    // On the employee screen every account is staff, so the lists are never
    // narrowed and there is no type control to narrow them.
    final staff = _staffOnly || values[kEmployeeField] != false;
    final options = assignmentOptions(staff: staff);
    return _staffOnly
        ? EmployeeForm(
            values: values,
            options: options,
            errors: errors,
            onChanged: onChanged,
            bare: true,
            lockPassword: !_c.editing,
          )
        : UserForm(
            values: values,
            options: options,
            errors: errors,
            onChanged: onChanged,
            bare: true,
            lockPassword: !_c.editing,
          );
  }

  UiTableRow _toRow(
    ManagedUser row,
    VoidCallback onEdit,
    Future<void> Function() onDelete,
  ) {
    // /api/user returns ids only. The names come from the reference lists this
    // host already holds, so no second round trip per row is needed.
    final linked = row.resolveNames(
      departments: {for (final d in departments) d.id: d.name},
      positions: {for (final p in positions) p.id: p.name},
    );
    return UiTableRow(
      cells: {
        'ID': linked.id,
        'First name': linked.firstName,
        'Last name': linked.lastName,
        'Email': linked.email,
        // Fall back to the id so a row whose reference is missing stays
        // identifiable instead of showing a blank cell.
        'Department': linked.departmentName.isEmpty
            ? linked.departmentId
            : linked.departmentName,
        'Position': linked.positionName.isEmpty
            ? linked.positionId
            : linked.positionName,
        if (_staffOnly)
          'Salary': linked.salary.toStringAsFixed(2)
        else
          'Employee': linked.isEmployee ? 'Yes' : 'No',
      },
      onEdit: onEdit,
      onDelete: () => onDelete(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = buildRows(_c, _openDialog, _toRow);
    final error = _c.error ??
        (optionsFailed
            ? 'Departments and positions could not be loaded, so the account '
                  'form is unavailable.'
            : null);
    // Never null. The pages read a null `onAdd` as "unwired" and open a static
    // preview form, so an unavailable form has to explain itself instead.
    void onAdd() => optionsFailed ? _explainNoOptions() : _openDialog();

    final page = _staffOnly
        ? EmployeeManagementPage(
            rows: rows,
            searchController: search,
            onSearchChanged: _c.search,
            onAdd: onAdd,
            loading: _c.stage == CrudStage.loading,
            error: error,
            notice: _c.notice,
            onRetry: () => afterFrame(_bootstrap),
            onDismiss: _c.dismissMessages,
            emptyLabel: _c.emptyLabel,
          )
        : UserManagementPage(
            rows: rows,
            searchController: search,
            onSearchChanged: _c.search,
            onAdd: onAdd,
            loading: _c.stage == CrudStage.loading,
            error: error,
            notice: _c.notice,
            onRetry: () => afterFrame(_bootstrap),
            onDismiss: _c.dismissMessages,
            emptyLabel: _c.emptyLabel,
          );

    return page;
  }
}
