import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/workflow_page.dart';
import 'widgets/booking_group_card.dart';

/// Group booking details in the presenter and supply one card per booking ID.
class BookingsPage extends StatelessWidget {
  const BookingsPage({
    super.key,
    this.bookings = const [],
    this.onSearchChanged,
  });
  final List<BookingGroupCard> bookings;
  final ValueChanged<String>? onSearchChanged;
  @override
  Widget build(BuildContext context) => WorkflowPage(
    title: 'View booked',
    section: 'BOOKING',
    children: [
      TextField(
        onChanged: onSearchChanged,
        decoration: const InputDecoration(
          labelText: 'Search bookings',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      if (bookings.isEmpty)
        const ZEmpty('No bookings yet', '')
      else
        ...bookings,
    ],
  );
}
