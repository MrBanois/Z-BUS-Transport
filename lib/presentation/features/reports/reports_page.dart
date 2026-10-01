import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/ui_fields.dart';
import '../../shared/ui_table.dart';
import '../../shared/workflow_page.dart';

/// Report titles are navigation metadata, not example report data. Query,
/// aggregate and export reports outside UI; supply columns and formatted rows.
class ReportsPage extends StatelessWidget {
  const ReportsPage({
    super.key,
    this.topic = 'Trip log',
    this.columns = const [
      'Date',
      'Route',
      'Schedule',
      'Seats booked',
      'Passengers boarded',
    ],
    this.rows = const [],
    this.values = const {},
    this.onTopicChanged,
    this.onChanged,
    this.onSearch,
    this.onExport,
  });
  static const topics = [
    'Trip log',
    'Booked trips',
    'Route usage',
    'Vehicle usage',
    'Passenger attendance',
  ];
  final String topic;
  final List<String> columns;
  final List<UiTableRow> rows;
  final Map<String, Object?> values;
  final ValueChanged<String?>? onTopicChanged;
  final void Function(String, Object?)? onChanged;
  final VoidCallback? onSearch, onExport;
  @override
  Widget build(BuildContext context) => WorkflowPage(
    title: 'Statistic reports',
    section: 'STATISTIC',
    children: [
      DropdownButtonFormField<String>(
        initialValue: topic,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Report'),
        items: [
          for (final t in topics) DropdownMenuItem(value: t, child: Text(t)),
        ],
        onChanged: onTopicChanged,
      ),
      UiFields(
        fields: const [
          UiFieldSpec('fromDate', 'From date'),
          UiFieldSpec('toDate', 'To date'),
        ],
        values: values,
        onChanged: onChanged,
      ),
      Wrap(
        spacing: 12,
        children: [
          ZButton('Search', onPressed: onSearch),
          ZButton('Export', secondary: true, onPressed: onExport),
        ],
      ),
      UiTable(columns: columns, rows: rows, emptyLabel: 'No report data'),
    ],
  );
}
