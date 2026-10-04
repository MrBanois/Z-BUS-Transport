import 'package:flutter/material.dart';

import '../../shared/crud_page.dart';
import '../../shared/page_copy.dart';
import '../../shared/ui_table.dart';
import 'widgets/user_form.dart';
import 'widgets/user_table.dart';

/// Managed accounts, staff and passengers alike.
///
/// Logic-free: rows, search text, list state and every callback arrive from the
/// presenter.
class UserManagementPage extends StatelessWidget {
  const UserManagementPage({
    super.key,
    this.rows = const [],
    this.onSearchChanged,
    this.onAdd,
    this.searchController,
    this.loading = false,
    this.error,
    this.notice,
    this.onRetry,
    this.onDismiss,
    this.emptyLabel = 'No records yet',
  });
  final List<UiTableRow> rows;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onAdd;
  final TextEditingController? searchController;
  final bool loading;
  final String? error, notice;
  final VoidCallback? onRetry, onDismiss;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) => CrudPage(
    title: masterUsers.headline,
    description: masterUsers.standfirst,
    index: masterUsers.index,
    kicker: masterUsers.kicker,
    searchLabel: 'Search users',
    sectionTitle: 'All users',
    table: UserTable(rows: rows),
    onSearchChanged: onSearchChanged,
    searchController: searchController,
    loading: loading,
    hasRows: rows.isNotEmpty,
    error: error,
    notice: notice,
    onRetry: onRetry,
    onDismiss: onDismiss,
    emptyTitle: emptyLabel,
    emptyMessage: loading ? '' : 'No accounts match this search.',
    onAdd:
        onAdd ??
        () => showDialog<void>(
          context: context,
          builder: (_) => const UserForm(),
        ),
  );
}
