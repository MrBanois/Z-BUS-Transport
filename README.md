# ZBus Transport UI mockups

Responsive Flutter mockups for the Mahanakorn University of Technology shuttle network in Nong Chok. The project draws its route, reservation, employee, driver, and reporting structure from the three artifacts in `Ref./`.

## Run

```bash
flutter pub get
flutter run -d chrome
```

Use the role selector on the login screen to enter the **operations**, **passenger**, or **driver** journey. Credentials are not needed in this prototype.

## Screens and flows

- Operations: overview, employees, editable position-permission matrix, routes, stops, schedules, vehicles, driver assignments, seven report views, account, and interface states.
- Passenger: stop-to-stop trip search, available departure list, seat selection, reservation confirmation with a visual QR token, and filtered reservation history with cancellation.
- Driver: daily assignments, run detail and passenger manifest, check-in validation states, and trip closeout.

Mock data mirrors the reference routes, Nong Chok stops, 9-seat vans, 20-seat buses, named drivers, and reservation statuses. The search applies a **20-minute** booking cutoff using a fixed **08:40 ICT preview clock**. Seat selection is capped at **four** and at the available capacity of the sample run.

This is a UI prototype with in-memory state. The displayed QR pattern is illustrative; use the visible token in the check-in mockup. Employee edits, schedule conflict checks, permissions, report exports, and authentication need backend integration before production use.

## Architecture

- `zbus_app.dart` owns session navigation and the in-memory reservation ledger.
- `zbus_data.dart` contains typed domain records and statuses.
- `zbus_domain.dart` contains route traversal, booking, capacity, cancellation, and check-in rules that can be tested without Flutter widgets.
- `zbus_fixtures.dart` contains the realistic reference-derived mock data.
- `zbus_pages.dart` composes the role-specific mockup screens.
- `zbus_widgets.dart` and `zbus_theme.dart` provide the shared design system.

Reservation records are immutable. The ledger accounts for seats booked and cancelled during the session, while route search applies the 20-minute cutoff to the passenger's actual boarding stop. These rules are intentionally isolated so a future API-backed repository can replace the in-memory ledger without changing the UI contract.

## Validation

```bash
flutter analyze
flutter test
flutter build web
```

The test suite covers passenger and driver workflows, retained page state, booking and cancellation capacity, repeated-stop routing, check-in outcomes, and every page at phone, tablet, and desktop widths.
