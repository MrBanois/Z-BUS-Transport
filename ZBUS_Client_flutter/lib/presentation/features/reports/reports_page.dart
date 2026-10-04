import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/page_copy.dart';
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
    title: analyticsReports.headline,
    section: 'STATISTIC',
    index: analyticsReports.index,
    kicker: analyticsReports.kicker,
    description: analyticsReports.standfirst,
    action: ZButton(
      'Export view',
      secondary: true,
      onPressed: onExport,
      icon: Icons.arrow_forward,
    ),
    children: [
      ZPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZLabel('01 / SELECTION', color: ZColors.accent),
            const ZGap(23),
            ZColumns(
              children: [
                ZSelect(
                  'Report view',
                  value: topic,
                  items: topics,
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
              ],
            ),
            const ZGap(22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ZButton('Search', onPressed: onSearch),
                ZButton('Export', secondary: true, onPressed: onExport),
              ],
            ),
          ],
        ),
      ),
      const ZGap(8),
      ZSectionTitle(
        '02 / DATA',
        rows.isEmpty ? 'No report data' : topic,
      ),
      UiTable(columns: columns, rows: rows, emptyLabel: 'No report data'),
      const ZGap(20),
      const ZNotice(
        'Aggregation happens upstream',
        'Seats booked and passengers boarded are distinct metrics. Compute '
        'them in the reporting layer and pass formatted values.',
        color: ZColors.success,
      ),
    ],
  );
}