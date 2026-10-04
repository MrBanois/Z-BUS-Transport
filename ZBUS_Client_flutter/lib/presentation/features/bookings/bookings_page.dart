import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/page_copy.dart';
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
    title: passengerBookings.headline,
    section: 'BOOKING',
    index: passengerBookings.index,
    kicker: passengerBookings.kicker,
    description: passengerBookings.standfirst,
    children: [
      ZSearch(hint: 'Search bookings', onChanged: onSearchChanged),
      const ZGap(30),
      ZSectionTitle(
        '01 / BOOKINGS',
        bookings.isEmpty ? 'Nothing reserved yet' : 'Your bookings',
      ),
      if (bookings.isEmpty)
        const ZEmpty(
          'No bookings yet',
          'Find a departure and reserve a seat to see it here.',
        )
      else
        ...bookings,
    ],
  );
}