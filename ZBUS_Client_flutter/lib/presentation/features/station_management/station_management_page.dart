import 'package:flutter/material.dart';

import '../../shared/crud_page.dart';
import '../../shared/page_copy.dart';
import '../../shared/ui_table.dart';
import 'widgets/station_form.dart';
import 'widgets/station_table.dart';

/// Empty by default. Inject rows, search and add handlers from your presenter.
/// The fallback Add action only opens the empty form; it does not create records.
class StationManagementPage extends StatelessWidget {
  const StationManagementPage({
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
    title: designStations.headline,
    description: designStations.standfirst,
    index: designStations.index,
    kicker: designStations.kicker,
    searchLabel: 'Search stations',
    sectionTitle: 'All stations',
    table: StationTable(rows: rows),
    onSearchChanged: onSearchChanged,
    onAdd:
        onAdd ??
        () => showDialog<void>(
          context: context,
          builder: (_) => const StationForm(),
        ),
  );
}