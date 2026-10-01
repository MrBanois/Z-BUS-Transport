import 'package:flutter/material.dart';

import '../../../shared/ui_table.dart';

/// Pass mapped presentation rows; department/position cells should contain names.
/// Attach edit/delete callbacks to each row from your application layer.
class UserTable extends StatelessWidget {
  const UserTable({super.key, this.rows = const []});
  final List<UiTableRow> rows;
  @override
  Widget build(BuildContext context) => UiTable(
    columns: const [
      'ID',
      'First name',
      'Last name',
      'Email',
      'Department',
      'Position',
      'Employee',
    ],
    rows: rows,
  );
}
