import 'package:flutter/material.dart';

import '../../shared/crud_page.dart';
import '../../shared/page_copy.dart';
import '../../shared/ui_table.dart';
import 'widgets/department_form.dart';
import 'widgets/department_table.dart';

/// Managed departments.
///
/// Logic-free: rows, search text, list state and every callback arrive from the
/// presenter. The fallback Add action only opens the empty form so a layout
/// preview still renders; it cannot create anything.
class DepartmentManagementPage extends StatelessWidget {
  const DepartmentManagementPage({
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

  /// Distinguishes "there are none" from "the search matched none".
  final String emptyLabel;

  @override
  Widget build(BuildContext context) => CrudPage(
    title: masterDepartments.headline,
    description: masterDepartments.standfirst,
    index: masterDepartments.index,
    kicker: masterDepartments.kicker,
    searchLabel: 'Search departments',
    sectionTitle: 'All departments',
    table: DepartmentTable(rows: rows),
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
        : 'Departments are the units every account is assigned to.',
    onAdd:
        onAdd ??
        () => showDialog<void>(
          context: context,
          builder: (_) => const DepartmentForm(),
        ),
  );
}
