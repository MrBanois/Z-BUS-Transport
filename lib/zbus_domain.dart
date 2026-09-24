import 'zbus_data.dart';

class BookingValidationException implements Exception {
  const BookingValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BookingRules {
  const BookingRules._();

  static const maxSeatsPerReservation = 4;
  static const bookingCutoffMinutes = 20;

  static String formatClockMinutes(int minutes) {
    final clock = minutes % (24 * 60);
    return '${(clock ~/ 60).toString().padLeft(2, '0')}:${(clock % 60).toString().padLeft(2, '0')}';
  }

  static int parseClockMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw FormatException('Expected a 24-hour time in HH:MM format.', value);
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        minute < 0 ||
        hour > 23 ||
        minute > 59) {
      throw FormatException('Expected a valid 24-hour time.', value);
    }
    return hour * 60 + minute;
  }

  static List<TripRecord> eligibleTrips({
    required String origin,
    required String destination,
    required int currentMinutes,
    required List<TripRecord> trips,
    required List<RouteRecord> routes,
  }) {
    final routeById = {for (final route in routes) route.id: route};
    return trips
        .where((trip) {
          final route = routeById[trip.route];
          final journey = route?.journeyBetween(origin, destination);
          if (journey == null) return false;
          final boardingMinutes =
              parseClockMinutes(trip.time) + journey.minutesFromRouteStart;
          return boardingMinutes - currentMinutes >= bookingCutoffMinutes;
        })
        .toList(growable: false);
  }

  static void validateSeatRequest({
    required int requestedSeats,
    required int availableSeats,
  }) {
    if (requestedSeats < 1) {
      throw const BookingValidationException(
        'At least one seat must be selected.',
      );
    }
    if (requestedSeats > maxSeatsPerReservation) {
      throw const BookingValidationException(
        'A reservation may contain at most four seats.',
      );
    }
    if (requestedSeats > availableSeats) {
      throw BookingValidationException(
        'Only $availableSeats seats remain on this run.',
      );
    }
  }
}

class ReservationLedger {
  ReservationLedger({
    required List<ReservationRecord> initialReservations,
    this.nextGeneratedNumber = 23,
  }) : _reservations = List.of(initialReservations);

  final List<ReservationRecord> _reservations;
  final Map<String, int> _seatAdjustments = {};
  int nextGeneratedNumber;

  List<ReservationRecord> get reservations => List.unmodifiable(_reservations);

  int availableSeats(TripRecord trip) =>
      (trip.available - (_seatAdjustments[trip.id] ?? 0)).clamp(
        0,
        trip.capacity,
      );

  ReservationRecord book({
    required TripRecord trip,
    required String origin,
    required String destination,
    required int seats,
  }) {
    BookingRules.validateSeatRequest(
      requestedSeats: seats,
      availableSeats: availableSeats(trip),
    );
    return bookGroup([
      BookingDraftTrip(
        trip: trip,
        origin: origin,
        destination: destination,
        seats: seats,
      ),
    ]).single;
  }

  List<ReservationRecord> bookGroup(List<BookingDraftTrip> details) {
    if (details.isEmpty) {
      throw const BookingValidationException(
        'Add at least one trip before confirming the booking.',
      );
    }
    final seatsByTrip = <String, int>{};
    for (final detail in details) {
      final alreadyRequested = seatsByTrip[detail.trip.id] ?? 0;
      BookingRules.validateSeatRequest(
        requestedSeats: detail.seats,
        availableSeats: availableSeats(detail.trip) - alreadyRequested,
      );
      seatsByTrip[detail.trip.id] = alreadyRequested + detail.seats;
    }

    final bookingId =
        'BKG-260914-${nextGeneratedNumber.toString().padLeft(3, '0')}';
    nextGeneratedNumber++;
    final reservations = <ReservationRecord>[];
    for (var index = 0; index < details.length; index++) {
      final detail = details[index];
      final detailNumber = (index + 1).toString().padLeft(2, '0');
      final reservation = ReservationRecord(
        bookingId,
        detail.trip.id,
        detail.trip.route,
        detail.origin,
        detail.destination,
        detail.trip.time,
        detail.seats,
        ReservationStatus.onWait,
        'QR-$bookingId-$detailNumber',
        detailNumber,
      );
      reservations.add(reservation);
      _seatAdjustments.update(
        detail.trip.id,
        (reserved) => reserved + detail.seats,
        ifAbsent: () => detail.seats,
      );
    }
    _reservations.insertAll(0, reservations);
    return List.unmodifiable(reservations);
  }

  final Map<String, int> boardedPassengers = {};

  ReservationRecord checkIn(String detailId, int passengers) {
    final index = _reservations.indexWhere((r) => r.detailId == detailId);
    if (index < 0) {
      throw const BookingValidationException('Booking detail not found.');
    }
    final booking = _reservations[index];
    if (booking.status != ReservationStatus.onWait) {
      throw const BookingValidationException(
        'Only waiting bookings can check in.',
      );
    }
    CheckInValidator.validatePassengerCount(passengers, booking.seats);
    boardedPassengers[detailId] = passengers;
    return _reservations[index] = booking.copyWith(
      status: ReservationStatus.checkedIn,
    );
  }

  ReservationRecord cancel(String reservationId) {
    final index = _reservations.indexWhere(
      (reservation) =>
          reservation.detailId == reservationId ||
          reservation.id == reservationId,
    );
    if (index < 0) {
      throw BookingValidationException(
        'Reservation $reservationId was not found.',
      );
    }
    final current = _reservations[index];
    if (!current.status.holdsSeats) return current;

    final cancelled = current.copyWith(status: ReservationStatus.cancelled);
    _reservations[index] = cancelled;
    final adjustedSeats =
        (_seatAdjustments[current.tripId] ?? 0) - current.seats;
    if (adjustedSeats == 0) {
      _seatAdjustments.remove(current.tripId);
    } else {
      _seatAdjustments[current.tripId] = adjustedSeats;
    }
    return cancelled;
  }

  List<ReservationRecord> cancelBooking(String bookingId) {
    final matching = _reservations
        .where((reservation) => reservation.id == bookingId)
        .toList();
    if (matching.isEmpty) {
      throw BookingValidationException('Booking $bookingId was not found.');
    }
    return [for (final reservation in matching) cancel(reservation.detailId)];
  }
}

enum CheckInResult {
  accepted,
  alreadyCheckedIn,
  wrongRun,
  wrongStop,
  notFound,
  unavailable,
}

class CheckInValidator {
  const CheckInValidator._();

  static void validatePassengerCount(int passengers, int seats) {
    if (passengers < 1 || passengers > seats) {
      throw BookingValidationException(
        'Enter between 1 and $seats boarded passengers. Use no-show when nobody boards.',
      );
    }
  }

  static CheckInResult validate({
    required String token,
    required String activeTripId,
    required String activeStop,
    required Iterable<ReservationRecord> reservations,
    required Set<String> scannedTokens,
  }) {
    ReservationRecord? reservation;
    for (final candidate in reservations) {
      if (candidate.token.toUpperCase() == token.trim().toUpperCase()) {
        reservation = candidate;
        break;
      }
    }
    if (reservation == null) return CheckInResult.notFound;
    if (reservation.tripId != activeTripId) return CheckInResult.wrongRun;
    if (reservation.from != activeStop) return CheckInResult.wrongStop;
    if (reservation.status == ReservationStatus.cancelled ||
        reservation.status == ReservationStatus.noShow) {
      return CheckInResult.unavailable;
    }
    if (reservation.status == ReservationStatus.checkedIn ||
        scannedTokens.contains(reservation.token)) {
      return CheckInResult.alreadyCheckedIn;
    }
    return CheckInResult.accepted;
  }
}
