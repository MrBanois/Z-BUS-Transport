import 'package:flutter/material.dart';

import '../../shared/crud_page.dart';
import '../../shared/page_copy.dart';
import '../../shared/ui_table.dart';
import 'widgets/department_form.dart';
import 'widgets/department_table.dart';

/// Empty by default. Inject rows, search and add handlers from your presenter.
/// The fallback Add action only opens the empty form; it does not create records.
class DepartmentManagementPage extends StatelessWidget {
  const DepartmentManagementPage({
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
    title: masterDepartments.headline,
    description: masterDepartments.standfirst,
    index: masterDepartments.index,
    kicker: masterDepartments.kicker,
    searchLabel: 'Search departments',
    sectionTitle: 'All departments',
    table: DepartmentTable(rows: rows),
    onSearchChanged: onSearchChanged,
    onAdd:
        onAdd ??
        () => showDialog<void>(
          context: context,
          builder: (_) => const DepartmentForm(),
        ),
  );
}