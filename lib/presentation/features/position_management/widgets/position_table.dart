import 'package:flutter/material.dart';

import '../../../shared/ui_table.dart';

/// Pass mapped presentation rows; department/position cells should contain names.
/// Attach edit/delete callbacks to each row from your application layer.
class PositionTable extends StatelessWidget {
  const PositionTable({super.key, this.rows = const []});
  final List<UiTableRow> rows;
  @override
  Widget build(BuildContext context) =>
      UiTable(columns: const ['ID', 'Name', 'Permissions'], rows: rows);
}
