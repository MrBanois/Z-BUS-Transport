import 'package:flutter/material.dart';

import '../../shared/crud_page.dart';
import '../../shared/page_copy.dart';
import '../../shared/ui_table.dart';
import 'widgets/schedule_form.dart';
import 'widgets/schedule_table.dart';

/// Empty by default. Inject rows, search and add handlers from your presenter.
/// The fallback Add action only opens the empty form; it does not create records.
class ScheduleManagementPage extends StatelessWidget {
  const ScheduleManagementPage({
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
    title: designSchedules.headline,
    description: designSchedules.standfirst,
    index: designSchedules.index,
    kicker: designSchedules.kicker,
    searchLabel: 'Search schedules',
    sectionTitle: 'All schedules',
    table: ScheduleTable(rows: rows),
    onSearchChanged: onSearchChanged,
    onAdd:
        onAdd ??
        () => showDialog<void>(
          context: context,
          builder: (_) => const ScheduleForm(),
        ),
  );
}