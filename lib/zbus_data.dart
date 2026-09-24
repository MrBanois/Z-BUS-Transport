enum ZRole { admin, passenger, driver }

class SessionUser {
  const SessionUser({
    required this.name,
    required this.email,
    required this.position,
    required this.role,
    required this.allowedPages,
  });

  final String name, email, position;
  final ZRole role;
  final Set<ZPage> allowedPages;
}

enum ReservationStatus {
  onWait('1', 'On wait'),
  checkedIn('2', 'Checked in'),
  cancelled('3', 'Cancelled'),
  noShow('4', 'No show');

  const ReservationStatus(this.code, this.label);
  final String code, label;

  bool get holdsSeats => this == ReservationStatus.onWait;
}

enum ZPage {
  departments,
  positions,
  users,
  routes,
  stops,
  schedules,
  vehicles,
  search,
  seats,
  bookingCart,
  confirmation,
  reservations,
  driverDay,
  driverTrip,
  checkIn,
  completion,
  reports,
  profile,
}

extension ZPageInfo on ZPage {
  String get label => switch (this) {
    ZPage.departments => 'Manage departments',
    ZPage.positions => 'Manage positions',
    ZPage.users => 'Manage users',
    ZPage.routes => 'Manage routes',
    ZPage.stops => 'Manage stations',
    ZPage.schedules => 'Manage schedules',
    ZPage.vehicles => 'Manage vehicles',
    ZPage.search => 'Find a trip',
    ZPage.seats => 'Reserve seats',
    ZPage.bookingCart => 'Booking cart',
    ZPage.confirmation => 'Your pass',
    ZPage.reservations => 'My reservations',
    ZPage.driverDay => 'My driving schedule',
    ZPage.driverTrip => 'Active trip',
    ZPage.checkIn => 'Scan passenger QR',
    ZPage.completion => 'Completed trip',
    ZPage.reports => 'Statistic reports',
    ZPage.profile => 'My account',
  };
}

class RouteRecord {
  const RouteRecord(
    this.id,
    this.name,
    this.stops,
    this.segmentMinutes,
    this.runs,
  );
  final String id, name;
  final List<String> stops;
  final List<int> segmentMinutes;
  final int runs;
  int get minutes =>
      segmentMinutes.fold(0, (total, minutes) => total + minutes);
  int minutesToStop(int index) =>
      segmentMinutes.take(index).fold(0, (total, minutes) => total + minutes);

  RouteJourney? journeyBetween(String origin, String destination) {
    for (var originIndex = 0; originIndex < stops.length - 1; originIndex++) {
      if (stops[originIndex] != origin) continue;
      for (
        var destinationIndex = originIndex + 1;
        destinationIndex < stops.length;
        destinationIndex++
      ) {
        if (stops[destinationIndex] == destination) {
          return RouteJourney(
            originIndex: originIndex,
            destinationIndex: destinationIndex,
            minutesFromRouteStart: minutesToStop(originIndex),
            journeyMinutes: segmentMinutes
                .skip(originIndex)
                .take(destinationIndex - originIndex)
                .fold(0, (total, minutes) => total + minutes),
          );
        }
      }
    }
    return null;
  }
}

class RouteJourney {
  const RouteJourney({
    required this.originIndex,
    required this.destinationIndex,
    required this.minutesFromRouteStart,
    required this.journeyMinutes,
  });

  final int originIndex;
  final int destinationIndex;
  final int minutesFromRouteStart;
  final int journeyMinutes;
}

class TripRecord {
  const TripRecord(
    this.id,
    this.route,
    this.time,
    this.arrival,
    this.driver,
    this.plate,
    this.capacity,
    this.available,
    this.status,
  );
  final String id, route, time, arrival, driver, plate, status;
  final int capacity, available;
}

class ReservationRecord {
  const ReservationRecord(
    this.id,
    this.tripId,
    this.route,
    this.from,
    this.to,
    this.time,
    this.seats,
    this.status,
    this.token, [
    this.detailNumber = '01',
  ]);
  final String id, tripId, route, from, to, time, token, detailNumber;
  String get detailId => '$id-$detailNumber';
  final int seats;
  final ReservationStatus status;

  ReservationRecord copyWith({ReservationStatus? status}) => ReservationRecord(
    id,
    tripId,
    route,
    from,
    to,
    time,
    seats,
    status ?? this.status,
    token,
    detailNumber,
  );
}

class BookingDraftTrip {
  const BookingDraftTrip({
    required this.trip,
    required this.origin,
    required this.destination,
    required this.seats,
  });

  final TripRecord trip;
  final String origin, destination;
  final int seats;
}
