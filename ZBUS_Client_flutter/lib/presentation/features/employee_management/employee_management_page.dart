import 'package:flutter/material.dart';

import '../../shared/crud_page.dart';
import '../../shared/page_copy.dart';
import '../../shared/ui_table.dart';
import 'widgets/employee_form.dart';
import 'widgets/employee_table.dart';

/// Managed staff accounts.
///
/// The same table as the user screen, narrowed to ISEMP = 'T' by the presenter.
/// Logic-free: rows, search text, list state and every callback arrive from it.
class EmployeeManagementPage extends StatelessWidget {
  const EmployeeManagementPage({
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
    title: masterEmployees.headline,
    description: masterEmployees.standfirst,
    index: masterEmployees.index,
    kicker: masterEmployees.kicker,
    searchLabel: 'Search employees',
    sectionTitle: 'All employees',
    table: EmployeeTable(rows: rows),
    onSearchChanged: onSearchChanged,
    searchController: searchController,
    loading: loading,
    hasRows: rows.isNotEmpty,
    error: error,
    notice: notice,
    onRetry: onRetry,
    onDismiss: onDismiss,
    emptyTitle: emptyLabel,
    emptyMessage: loading
        ? ''
        : 'Staff accounts only. An employee\'s assignment is set here, not on '
              'their own account screen.',
    onAdd:
        onAdd ??
        () => showDialog<void>(
          context: context,
          builder: (_) => const EmployeeForm(),
        ),
  );
}
