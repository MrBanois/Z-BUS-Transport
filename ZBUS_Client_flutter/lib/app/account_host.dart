import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../presentation/features/account/account_page.dart';
import '../presentation/shared/permissions.dart';
import '../presentation/shared/ui_fields.dart';
import 'account_controller.dart';

/// Binds [AccountController] to the controlled [AccountPage].
///
/// This is where the two layers meet, which is why it lives in `app/` rather than
/// in the feature folder: the screen stays unaware of the controller, and the
/// controller stays unaware of widgets. The dropdown `UiOption`s are built here
/// too, so neither side has to know the other's vocabulary.
///
/// The read is scheduled from the element lifecycle rather than from `build`, so
/// the controller's first `notifyListeners` cannot land inside a build and throw.
class AccountHost extends StatefulWidget {
  const AccountHost({
    super.key,
    required this.controller,
    required this.session,
  });

  final AccountController controller;

  /// Supplies the id to load and the screen access to display.
  final Session session;

  @override
  State<AccountHost> createState() => _AccountHostState();
}

class _AccountHostState extends State<AccountHost> {
  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(covariant AccountHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different signed-in member means different rows: load theirs, not the
    // previous one's.
    if (oldWidget.session.id != widget.session.id) _scheduleLoad();
  }

  void _scheduleLoad() {
    final id = widget.session.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.load(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final profile = controller.profile;
        final failed = controller.stage == ProfileStage.failed;
        return AccountPage(
          loading: controller.loading,
          saving: controller.saving,
          failed: failed,
          dirty: controller.dirty,
          optionsLoading: controller.optionsLoading,
          isEmployee: controller.isEmployee,
          memberId: profile?.id ?? widget.session.id,
          email: profile?.email ?? widget.session.email,
          departmentName: profile?.departmentName ?? '',
          positionName: profile?.positionName ?? '',
          grantedScreens: _granted(),
          values: {
            // The id field mirrors the record rather than the draft, so it stays
            // stable while the name is being edited.
            'id': profile?.id ?? widget.session.id,
            ...controller.values,
          },
          options: {
            'department': _options(controller.departments),
            'position': _options(controller.positions),
          },
          errors: controller.fieldErrors,
          error: controller.error,
          notice: controller.notice,
          onChanged: controller.set,
          onSave: controller.save,
          onRetry: () => controller.load(widget.session.id, force: true),
          onDiscard: controller.revert,
        );
      },
    );
  }

  /// Listed in the canonical bit order rather than the set's own order, so the
  /// panel matches the sidebar's numbering instead of jumping about.
  List<String> _granted() => [
    for (final screen in kPermissionOrder)
      if (widget.session.permissions.contains(screen)) screen,
  ];

  List<UiOption> _options(List<ChoiceOption> source) => [
    for (final option in source)
      UiOption(option.id, option.name.isEmpty ? option.id : option.label),
  ];
}
