/// Editorial header copy for every screen.
///
/// The design language depends on an oversized, hand-broken headline per page
/// (`WHERE TO\nNEXT?`) instead of a single repeated Material title. Keeping the
/// copy in one place lets both a feature page and the navigation layer agree on
/// wording without either of them owning the other's concerns.
class PageCopy {
  const PageCopy({
    required this.index,
    required this.kicker,
    required this.headline,
    required this.standfirst,
  });
  final String index, kicker, headline, standfirst;
}

const passengerBooking = PageCopy(
  index: '09 / BOOKING',
  kicker: 'PASSENGER / PLAN A RIDE',
  headline: 'WHERE TO\nNEXT?',
  standfirst:
      'Choose your boarding and destination stops. Only runs with enough time '
      'to reserve before boarding are returned.',
);

const passengerBookings = PageCopy(
  index: '12 / BOOKING',
  kicker: 'PASSENGER / RESERVATIONS',
  headline: 'YOUR\nRESERVATIONS.',
  standfirst:
      'Every booking you hold, grouped by booking ID. Each trip keeps its own '
      'detail number, QR token, seats and cancellation status.',
);

const memberAccount = PageCopy(
  index: '18 / MEMBER',
  kicker: 'MEMBER / ACCOUNT',
  headline: 'YOUR PLACE\nIN THE NETWORK.',
  standfirst:
      'Keep your identity and contact details current. Position determines '
      'which parts of the system appear in your navigation.',
);

const driverSchedule = PageCopy(
  index: '13 / DRIVER',
  kicker: 'DRIVER / SCHEDULE',
  headline: 'THE DAY\nAHEAD.',
  standfirst:
      'Only runs assigned to you are listed. Start, hand over and cancel '
      'actions belong to each row and are decided by your presenter.',
);

const driverActiveTrip = PageCopy(
  index: '14 / DRIVER',
  kicker: 'DRIVER / ACTIVE TRIP',
  headline: 'ON THE\nROAD.',
  standfirst:
      'The run in progress, its station timetable and the passenger manifest. '
      'Scan a QR token to board a passenger.',
);

const driverCheckIn = PageCopy(
  index: '15 / DRIVER',
  kicker: 'DRIVER / CHECK-IN',
  headline: 'SCAN. VERIFY.\nLET THEM RIDE.',
  standfirst:
      'Scan a passenger QR, verify the booking, then confirm how many people '
      'are actually boarding this stop.',
);

const masterDepartments = PageCopy(
  index: '02 / MASTER FILE',
  kicker: 'MASTER FILE / DEPARTMENTS',
  headline: 'TEAMS BEHIND\nTHE JOURNEY.',
  standfirst:
      'Passenger IDs begin PD; employee IDs begin ED. A department cannot be '
      'removed while users still reference it.',
);

const masterAccess = PageCopy(
  index: '03 / MASTER FILE',
  kicker: 'MASTER FILE / ACCESS',
  headline: 'ACCESS IS\nASSIGNED.',
  standfirst:
      'Define which screens each position can reach. Privileges are never '
      'hard-coded to a fixed admin role.',
);

const masterUsers = PageCopy(
  index: '04 / MASTER FILE',
  kicker: 'MASTER FILE / USERS',
  headline: 'ONE USER TABLE.\nEVERY PERSON.',
  standfirst:
      'All passengers and employees, including department and position. '
      'Employee accounts carry ISEMP = T and a salary.',
);

const masterEmployees = PageCopy(
  index: '04 / MASTER FILE',
  kicker: 'MASTER FILE / EMPLOYEES',
  headline: 'PEOPLE BEHIND\nTHE SERVICE.',
  standfirst:
      'The employee subset of the same user table, with salary. Department '
      'and position stay locked to employee ranges.',
);

const designStations = PageCopy(
  index: '05 / SERVICE DESIGN',
  kicker: 'SERVICE DESIGN / STATIONS',
  headline: 'EVERY\nSTOP.',
  standfirst:
      'The shared stopping points every route is built from. A stop can belong '
      'to several routes and can reappear on a return leg.',
);

const designVehicles = PageCopy(
  index: '06 / SERVICE DESIGN',
  kicker: 'SERVICE DESIGN / VEHICLES',
  headline: 'THE FLEET\nIN MOTION.',
  standfirst:
      'Plate, capacity and type for each vehicle. Capacity feeds the seat '
      'availability shown to passengers.',
);

const designRoutes = PageCopy(
  index: '07 / SERVICE DESIGN',
  kicker: 'SERVICE DESIGN / ROUTES',
  headline: 'LINES THROUGH\nNONG CHOK.',
  standfirst:
      'Build a route from ordered stops. Total duration is derived from each '
      'consecutive stop segment.',
);

const designSchedules = PageCopy(
  index: '08 / SERVICE DESIGN',
  kicker: 'SERVICE DESIGN / SCHEDULES',
  headline: 'WHEN THE\nNETWORK RUNS.',
  standfirst:
      'Departures with their driver and vehicle. Change a schedule and every '
      'booking search result follows.',
);

const analyticsReports = PageCopy(
  index: '17 / ANALYTICS',
  kicker: 'ANALYTICS / SERVICE INTELLIGENCE',
  headline: 'READ THE\nMOVEMENT.',
  standfirst:
      'Explore demand, booking outcomes, passenger behaviour and utilisation. '
      'Aggregate outside the UI and pass formatted rows.',
);