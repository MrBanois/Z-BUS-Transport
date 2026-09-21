enum ZRole { admin, passenger, driver }

enum ReservationStatus {
  confirmed('Confirmed'),
  checkedIn('Checked in'),
  completed('Completed'),
  cancelled('Cancelled');

  const ReservationStatus(this.label);
  final String label;

  bool get holdsSeats => this == ReservationStatus.confirmed;
}

enum ZPage {
  dashboard,
  staff,
  permissions,
  routes,
  stops,
  schedules,
  vehicles,
  assignments,
  search,
  seats,
  confirmation,
  reservations,
  driverDay,
  driverTrip,
  checkIn,
  completion,
  reports,
  profile,
  states,
}

extension ZPageInfo on ZPage {
  String get label => switch (this) {
    ZPage.dashboard => 'Overview',
    ZPage.staff => 'People',
    ZPage.permissions => 'Access',
    ZPage.routes => 'Routes',
    ZPage.stops => 'Stops',
    ZPage.schedules => 'Schedules',
    ZPage.vehicles => 'Vehicles',
    ZPage.assignments => 'Assignments',
    ZPage.search => 'Find a trip',
    ZPage.seats => 'Reserve seats',
    ZPage.confirmation => 'Your pass',
    ZPage.reservations => 'My reservations',
    ZPage.driverDay => 'My day',
    ZPage.driverTrip => 'Trip detail',
    ZPage.checkIn => 'Check-in',
    ZPage.completion => 'Trip summary',
    ZPage.reports => 'Reports',
    ZPage.profile => 'Account',
    ZPage.states => 'Interface states',
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
    this.token,
  );
  final String id, tripId, route, from, to, time, token;
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
  );
}
