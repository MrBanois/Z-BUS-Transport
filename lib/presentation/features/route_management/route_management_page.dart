import 'package:flutter/material.dart';

import '../../shared/crud_page.dart';
import '../../shared/ui_table.dart';
import 'widgets/route_table.dart';
import 'widgets/route_form.dart';

/// Empty by default. Inject rows, search and add handlers from your presenter.
/// The fallback Add action only opens the empty form; it does not create records.
class RouteManagementPage extends StatelessWidget {
  const RouteManagementPage({
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
    title: 'Manage routes',
    table: RouteTable(rows: rows),
    onSearchChanged: onSearchChanged,
    onAdd:
        onAdd ??
        () => showDialog<void>(
          context: context,
          builder: (_) => const RouteForm(),
        ),
  );
}
