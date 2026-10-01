import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/ui_fields.dart';
import '../../shared/ui_table.dart';
import '../../shared/workflow_page.dart';
import 'widgets/station_timetable.dart';
import 'widgets/seat_selection.dart';

/// Connect search to a schedule query. Supply result-row actions to select a
/// schedule and update timetableRows. Cart membership and booking are external.
class BookingPage extends StatelessWidget {
  const BookingPage({
    super.key,
    this.values = const {},
    this.options = const {},
    this.schedules = const [],
    this.cart = const [],
    this.timetableRows = const [],
    this.onChanged,
    this.onSearch,
    this.onBook,
    this.draftValues = const {},
    this.draftOptions = const {},
    this.onDraftChanged,
    this.onAddTrip,
  });
  final Map<String, Object?> values, draftValues;
  final Map<String, List<UiOption>> options, draftOptions;
  final List<UiTableRow> schedules, cart, timetableRows;
  final void Function(String, Object?)? onChanged, onDraftChanged;
  final VoidCallback? onSearch, onBook, onAddTrip;
  @override
  Widget build(BuildContext context) => WorkflowPage(
    title: 'Where to next?',
    section: 'BOOKING',
    children: [
      ZPanel(
        child: UiFields(
          fields: const [
            UiFieldSpec('date', 'Travel date'),
            UiFieldSpec('pickup', 'Pickup station', kind: UiFieldKind.select),
            UiFieldSpec(
              'dropOff',
              'Drop-off station',
              kind: UiFieldKind.select,
            ),
          ],
          values: values,
          options: options,
          onChanged: onChanged,
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: ZButton('Find schedules', onPressed: onSearch),
      ),
      UiTable(
        columns: const ['Route', 'Schedule', 'Departure', 'Available seats'],
        rows: schedules,
        emptyLabel: 'No schedules selected',
      ),
      StationTimetable(rows: timetableRows),
      SeatSelection(
        values: draftValues,
        options: draftOptions,
        onChanged: onDraftChanged,
        onAdd: onAddTrip,
      ),
      const ZLabel('Booking cart'),
      UiTable(
        columns: const ['Route', 'Schedule', 'Pickup', 'Drop-off', 'Seats'],
        rows: cart,
        emptyLabel: 'No trips added',
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: ZButton('Book selected trips', onPressed: onBook),
      ),
    ],
  );
}
