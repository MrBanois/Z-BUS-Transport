import 'package:flutter/material.dart';

import 'design_system.dart';
import 'theme.dart';

/// Presentation data only. Map your application results into named cells.
/// Keep record IDs in callback closures; never use a displayed name as a key.
class UiTableRow {
  const UiTableRow({
    required this.cells,
    this.onEdit,
    this.onDelete,
    this.actions,
  });
  final Map<String, String> cells;
  final VoidCallback? onEdit, onDelete;
  final Widget? actions;
}

/// No fetching, sorting or filtering occurs here. Pass already prepared rows.
class UiTable extends StatelessWidget {
  const UiTable({
    super.key,
    required this.columns,
    this.rows = const [],
    this.emptyLabel = 'No records yet',
    this.showActions = true,
  });
  final List<String> columns;
  final List<UiTableRow> rows;
  final String emptyLabel;
  final bool showActions;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: ZTheme.mono(11, color: ZColors.ink),
          columns: [
            for (final column in columns) DataColumn(label: Text(column)),
            if (showActions) const DataColumn(label: Text('Actions')),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  for (final column in columns)
                    DataCell(Text(row.cells[column] ?? '—')),
                  if (showActions)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (row.actions != null)
                            row.actions!
                          else ...[
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: row.onEdit,
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: row.onDelete,
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
      if (rows.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ZEmpty(emptyLabel, ''),
        ),
    ],
  );
}
