import 'package:flutter/material.dart';

import '../../shared/crud_page.dart';
import '../../shared/page_copy.dart';
import '../../shared/ui_table.dart';
import 'widgets/vehicle_form.dart';
import 'widgets/vehicle_table.dart';

/// Empty by default. Inject rows, search and add handlers from your presenter.
/// The fallback Add action only opens the empty form; it does not create records.
class VehicleManagementPage extends StatelessWidget {
  const VehicleManagementPage({
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
    title: designVehicles.headline,
    description: designVehicles.standfirst,
    index: designVehicles.index,
    kicker: designVehicles.kicker,
    searchLabel: 'Search vehicles',
    sectionTitle: 'All vehicles',
    table: VehicleTable(rows: rows),
    onSearchChanged: onSearchChanged,
    onAdd:
        onAdd ??
        () => showDialog<void>(
          context: context,
          builder: (_) => const VehicleForm(),
        ),
  );
}