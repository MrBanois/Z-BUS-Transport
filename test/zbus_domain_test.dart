import 'package:flutter_test/flutter_test.dart';
import 'package:zbus_transport/zbus_data.dart';
import 'package:zbus_transport/zbus_domain.dart';
import 'package:zbus_transport/zbus_fixtures.dart';

void main() {
  group('RouteRecord', () {
    test('selects the first valid forward segment when stops repeat', () {
      final journey = routes.first.journeyBetween(stops[1], stops[2]);

      expect(journey, isNotNull);
      expect(journey!.originIndex, 1);
      expect(journey.destinationIndex, 2);
      expect(journey.minutesFromRouteStart, 5);
      expect(journey.journeyMinutes, 3);
    });

    test('rejects a destination that is not after the origin', () {
      final journey = routes[1].journeyBetween(stops[4], stops[1]);

      expect(journey, isNull);
    });
  });

  group('BookingRules', () {
    test('includes a trip exactly at the booking cutoff', () {
      const candidate = TripRecord(
        'RUN-CUTOFF',
        'R01',
        '08:55',
        '09:25',
        'Driver',
        'TEST 1',
        9,
        9,
        'Scheduled',
      );

      final eligible = BookingRules.eligibleTrips(
        origin: stops[1],
        destination: stops[2],
        currentMinutes: 8 * 60 + 40,
        trips: const [candidate],
        routes: routes,
      );

      expect(eligible, [candidate]);
    });

    test('excludes a trip inside the booking cutoff', () {
      const candidate = TripRecord(
        'RUN-TOO-SOON',
        'R01',
        '08:54',
        '09:24',
        'Driver',
        'TEST 1',
        9,
        9,
        'Scheduled',
      );

      final eligible = BookingRules.eligibleTrips(
        origin: stops[1],
        destination: stops[2],
        currentMinutes: 8 * 60 + 40,
        trips: const [candidate],
        routes: routes,
      );

      expect(eligible, isEmpty);
    });

    test('rejects more than four seats', () {
      expect(
        () => BookingRules.validateSeatRequest(
          requestedSeats: 5,
          availableSeats: 9,
        ),
        throwsA(isA<BookingValidationException>()),
      );
    });
  });

  group('ReservationLedger', () {
    test('booking consumes capacity and cancellation restores it', () {
      final ledger = ReservationLedger(initialReservations: const []);
      final trip = trips.first;

      final reservation = ledger.book(
        trip: trip,
        origin: stops[0],
        destination: stops[2],
        seats: 2,
      );

      expect(ledger.availableSeats(trip), 1);
      expect(
        () => ledger.book(
          trip: trip,
          origin: stops[0],
          destination: stops[2],
          seats: 2,
        ),
        throwsA(isA<BookingValidationException>()),
      );

      final cancelled = ledger.cancel(reservation.id);
      expect(cancelled.status, ReservationStatus.cancelled);
      expect(ledger.availableSeats(trip), 3);
    });

    test('fresh fixture lists do not share mutable reservation state', () {
      final first = ReservationLedger(
        initialReservations: createInitialReservations(),
      );
      final second = ReservationLedger(
        initialReservations: createInitialReservations(),
      );

      first.cancel(first.reservations.first.id);

      expect(first.reservations.first.status, ReservationStatus.cancelled);
      expect(second.reservations.first.status, ReservationStatus.onWait);
    });

    test('cancelling an initial reservation releases its seats', () {
      final ledger = ReservationLedger(
        initialReservations: createInitialReservations(),
      );

      ledger.cancel('BKG-240914-018');

      expect(ledger.availableSeats(trips.first), 5);
    });

    test('grouped booking shares an ID and gives every trip its own QR', () {
      final ledger = ReservationLedger(initialReservations: const []);

      final booked = ledger.bookGroup([
        BookingDraftTrip(
          trip: trips[2],
          origin: stops[0],
          destination: stops[2],
          seats: 1,
        ),
        BookingDraftTrip(
          trip: trips[3],
          origin: stops[0],
          destination: stops[4],
          seats: 1,
        ),
      ]);

      expect(booked, hasLength(2));
      expect(booked[0].id, booked[1].id);
      expect(booked[0].detailNumber, '01');
      expect(booked[1].detailNumber, '02');
      expect(booked[0].token, isNot(booked[1].token));
    });

    test(
      'a detail can be cancelled without cancelling its booking siblings',
      () {
        final ledger = ReservationLedger(initialReservations: const []);
        final booked = ledger.bookGroup([
          BookingDraftTrip(
            trip: trips[2],
            origin: stops[0],
            destination: stops[2],
            seats: 1,
          ),
          BookingDraftTrip(
            trip: trips[3],
            origin: stops[0],
            destination: stops[4],
            seats: 1,
          ),
        ]);

        ledger.cancel(booked.first.detailId);

        expect(ledger.reservations[0].status, ReservationStatus.cancelled);
        expect(ledger.reservations[1].status, ReservationStatus.onWait);
      },
    );

    test('whole-booking cancellation cancels every active detail', () {
      final ledger = ReservationLedger(initialReservations: const []);
      final booked = ledger.bookGroup([
        BookingDraftTrip(
          trip: trips[2],
          origin: stops[0],
          destination: stops[2],
          seats: 1,
        ),
        BookingDraftTrip(
          trip: trips[3],
          origin: stops[0],
          destination: stops[4],
          seats: 1,
        ),
      ]);

      ledger.cancelBooking(booked.first.id);

      expect(
        ledger.reservations.map((reservation) => reservation.status),
        everyElement(ReservationStatus.cancelled),
      );
    });
  });

  group('CheckInValidator', () {
    final reservations = createInitialReservations();

    test('accepts the correct trip and stop', () {
      expect(
        CheckInValidator.validate(
          token: 'qr-bkg-240914-018-01',
          activeTripId: trips.first.id,
          activeStop: stops[0],
          reservations: reservations,
          scannedTokens: const {},
        ),
        CheckInResult.accepted,
      );
    });

    test('distinguishes wrong run, wrong stop, and unknown token', () {
      expect(
        CheckInValidator.validate(
          token: 'QR-BKG-220914-007',
          activeTripId: trips.first.id,
          activeStop: stops[0],
          reservations: reservations,
          scannedTokens: const {},
        ),
        CheckInResult.wrongRun,
      );
      expect(
        CheckInValidator.validate(
          token: 'QR-BKG-240914-018-01',
          activeTripId: trips.first.id,
          activeStop: stops[1],
          reservations: reservations,
          scannedTokens: const {},
        ),
        CheckInResult.wrongStop,
      );
      expect(
        CheckInValidator.validate(
          token: 'UNKNOWN',
          activeTripId: trips.first.id,
          activeStop: stops[0],
          reservations: reservations,
          scannedTokens: const {},
        ),
        CheckInResult.notFound,
      );
    });
  });
}
