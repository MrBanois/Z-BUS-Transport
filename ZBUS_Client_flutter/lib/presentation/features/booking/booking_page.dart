import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/page_copy.dart';
import '../../shared/ui_fields.dart';
import '../../shared/ui_table.dart';
import '../../shared/workflow_page.dart';
import 'widgets/seat_selection.dart';
import 'widgets/station_timetable.dart';

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
    this.onAddTrip,
    this.draftValues = const {},
    this.draftOptions = const {},
    this.onDraftChanged,
  });
  final Map<String, Object?> values, draftValues;
  final Map<String, List<UiOption>> options, draftOptions;
  final List<UiTableRow> schedules, cart, timetableRows;
  final void Function(String, Object?)? onChanged, onDraftChanged;
  final VoidCallback? onSearch, onBook, onAddTrip;
  @override
  Widget build(BuildContext context) => WorkflowPage(
    title: passengerBooking.headline,
    section: 'BOOKING',
    index: passengerBooking.index,
    kicker: passengerBooking.kicker,
    description: passengerBooking.standfirst,
    action: cart.isEmpty
        ? const ZStatus('NETWORK OPERATING')
        : ZButton(
            'Review ${cart.length} ${cart.length == 1 ? 'trip' : 'trips'}',
            onPressed: onBook,
            icon: Icons.shopping_bag_outlined,
          ),
    children: [
      ZPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZLabel('01 / YOUR JOURNEY', color: ZColors.accent),
            const ZGap(23),
            ZColumns(
              children: [
                _JourneyField(
                  spec: const UiFieldSpec(
                    'pickup',
                    'Board at',
                    kind: UiFieldKind.select,
                  ),
                  values: values,
                  options: options,
                  onChanged: onChanged,
                ),
                _JourneyField(
                  spec: const UiFieldSpec(
                    'dropOff',
                    'Get off at',
                    kind: UiFieldKind.select,
                  ),
                  values: values,
                  options: options,
                  onChanged: onChanged,
                ),
                _JourneyField(
                  spec: const UiFieldSpec('date', 'Travel date'),
                  values: values,
                  options: options,
                  onChanged: onChanged,
                ),
              ],
            ),
            const ZGap(22),
            ZButton(
              'Find departures',
              onPressed: onSearch,
              icon: Icons.arrow_forward,
            ),
            const ZGap(20),
            const Text(
              'Reservations close 20 minutes before arrival at your boarding '
              'stop.',
              style: TextStyle(fontSize: 12, color: ZColors.muted),
            ),
          ],
        ),
      ),
      const ZGap(20),
      ZSectionTitle(
        '02 / RESULTS',
        schedules.isEmpty ? 'Find your next run' : 'Available departures',
      ),
      UiTable(
        columns: const ['Route', 'Schedule', 'Departure', 'Available seats'],
        rows: schedules,
        emptyLabel: 'No schedules selected',
      ),
      if (timetableRows.isNotEmpty) ...[
        const ZGap(24),
        ZSectionTitle('03 / TIMETABLE', 'Stops and arrival times'),
        StationTimetable(rows: timetableRows),
      ],
      const ZGap(24),
      ZSectionTitle('04 / RESERVATION', 'Add a trip to this booking'),
      SeatSelection(
        values: draftValues,
        options: draftOptions,
        onChanged: onDraftChanged,
        onAdd: onAddTrip,
      ),
      const ZGap(24),
      ZSectionTitle('05 / CART', 'Trips in this booking'),
      UiTable(
        columns: const ['Route', 'Schedule', 'Pickup', 'Drop-off', 'Seats'],
        rows: cart,
        emptyLabel: 'No trips added',
      ),
      ZButton(
        'Book selected trips',
        onPressed: onBook,
        icon: Icons.arrow_forward,
      ),
    ],
  );
}

/// Single field rendered on its own so the three journey inputs can share the
/// responsive [ZColumns] grid without stretching across the full panel.
class _JourneyField extends StatelessWidget {
  const _JourneyField({
    required this.spec,
    required this.values,
    required this.options,
    this.onChanged,
  });
  final UiFieldSpec spec;
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final void Function(String, Object?)? onChanged;
  @override
  Widget build(BuildContext context) => UiFields(
    fields: [spec],
    values: values,
    options: options,
    onChanged: onChanged,
  );
}