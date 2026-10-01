import 'package:flutter/material.dart';

import '../../../shared/ui_table.dart';

/// Pass mapped presentation rows; department/position cells should contain names.
/// Attach edit/delete callbacks to each row from your application layer.
class VehicleTable extends StatelessWidget {
  const VehicleTable({super.key, this.rows = const []});
  final List<UiTableRow> rows;
  @override
  Widget build(BuildContext context) => UiTable(
    columns: const ['ID', 'Plate', 'Seats', 'Type', 'Active'],
    rows: rows,
  );
}
