import 'package:flutter/material.dart';

import '../../shared/crud_page.dart';
import '../../shared/ui_table.dart';
import 'widgets/user_table.dart';
import 'widgets/user_form.dart';

/// Empty by default. Inject rows, search and add handlers from your presenter.
/// The fallback Add action only opens the empty form; it does not create records.
class UserManagementPage extends StatelessWidget {
  const UserManagementPage({
    super.key,
    this.rows = const [],
    this.onSearchChanged,
    this.onAdd,
  });
  final List<UiTableRow> rows;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) => CrudPage(
    title: 'Manage users',
    table: UserTable(rows: rows),
    onSearchChanged: onSearchChanged,
    onAdd:
        onAdd ??
        () => showDialog<void>(
          context: context,
          builder: (_) => const UserForm(),
        ),
  );
}
