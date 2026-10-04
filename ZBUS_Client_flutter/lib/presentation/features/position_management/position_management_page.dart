import 'package:flutter/material.dart';

import '../../shared/crud_page.dart';
import '../../shared/page_copy.dart';
import '../../shared/ui_table.dart';
import 'widgets/position_form.dart';
import 'widgets/position_table.dart';

/// Managed positions, and the permission mask each one carries.
///
/// Logic-free: rows, search text, list state and every callback arrive from the
/// presenter.
class PositionManagementPage extends StatelessWidget {
  const PositionManagementPage({
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
    title: masterAccess.headline,
    description: masterAccess.standfirst,
    index: masterAccess.index,
    kicker: masterAccess.kicker,
    searchLabel: 'Search positions',
    sectionTitle: 'Positions and permissions',
    table: PositionTable(rows: rows),
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
        : 'A position decides which screens an account can reach.',
    onAdd:
        onAdd ??
        () => showDialog<void>(
          context: context,
          builder: (_) => const PositionForm(),
        ),
  );
}
