import 'package:flutter/material.dart';

import '../../shared/crud_page.dart';
import '../../shared/page_copy.dart';
import '../../shared/ui_table.dart';
import 'widgets/position_form.dart';
import 'widgets/position_table.dart';

/// Empty by default. Inject rows, search and add handlers from your presenter.
/// The fallback Add action only opens the empty form; it does not create records.
class PositionManagementPage extends StatelessWidget {
  const PositionManagementPage({
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
    title: masterAccess.headline,
    description: masterAccess.standfirst,
    index: masterAccess.index,
    kicker: masterAccess.kicker,
    searchLabel: 'Search positions',
    sectionTitle: 'Positions and permissions',
    table: PositionTable(rows: rows),
    onSearchChanged: onSearchChanged,
    onAdd:
        onAdd ??
        () => showDialog<void>(
          context: context,
          builder: (_) => const PositionForm(),
        ),
  );
}