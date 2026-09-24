import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zbus_transport/zbus_app.dart';
import 'package:zbus_transport/zbus_data.dart';
import 'package:zbus_transport/zbus_fixtures.dart';
import 'package:zbus_transport/zbus_pages.dart';
import 'package:zbus_transport/zbus_theme.dart';

void main() {
  testWidgets('Passenger can enter and open trip search', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ZBusApp());
    expect(find.text('WELCOME\nABOARD.'), findsOneWidget);
    await tester.ensureVisible(find.text('ENTER ZBUS'));
    await tester.tap(find.text('ENTER ZBUS'));
    await tester.pumpAndSettle();
    expect(find.text('WHERE TO\nNEXT?'), findsOneWidget);
    expect(find.text('FIND DEPARTURES'), findsOneWidget);
    await tester.tap(find.text('MORE'));
    await tester.pumpAndSettle();
    expect(find.text('01 / USER'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('02 / DRIVER'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('02 / DRIVER'), findsOneWidget);
  });

  testWidgets('Passenger can reserve a seat and see a pass', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ZBusApp());
    await tester.ensureVisible(find.text('ENTER ZBUS'));
    await tester.tap(find.text('ENTER ZBUS'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('FIND DEPARTURES'));
    await tester.tap(find.text('FIND DEPARTURES'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('RESERVE THIS TRIP').first);
    await tester.tap(find.text('RESERVE THIS TRIP').first);
    await tester.pumpAndSettle();
    expect(find.text('MAKE ROOM\nFOR THE RIDE.'), findsOneWidget);
    await tester.ensureVisible(find.text('ADD TRIP · 1 SEAT'));
    await tester.tap(find.text('ADD TRIP · 1 SEAT'));
    await tester.pumpAndSettle();
    expect(find.text('WHERE TO\nNEXT?'), findsOneWidget);
    await tester.ensureVisible(find.text('REVIEW 1 TRIP'));
    await tester.tap(find.text('REVIEW 1 TRIP'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('CONFIRM BOOKING'));
    await tester.tap(find.text('CONFIRM BOOKING'));
    await tester.pumpAndSettle();
    expect(find.text('YOU ARE\nON BOARD.'), findsOneWidget);
  });

  testWidgets('Page form state survives navigation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ZBusApp());
    await tester.ensureVisible(find.text('ENTER ZBUS'));
    await tester.tap(find.text('ENTER ZBUS'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('MY ACCOUNT'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Updated Passenger');
    await tester.tap(find.text('FIND A TRIP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MY ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('Updated Passenger'), findsWidgets);
  });

  testWidgets('Driver can start a run and open check-in', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ZBusApp());
    await tester.enterText(find.byType(TextField).first, 'driver@mut.edu');
    await tester.ensureVisible(find.text('ENTER ZBUS'));
    await tester.tap(find.text('ENTER ZBUS'));
    await tester.pumpAndSettle();
    expect(find.text('MY DRIVING\nSCHEDULE.'), findsOneWidget);
    await tester.ensureVisible(find.text('START TRIP').first);
    await tester.tap(find.text('START TRIP').first);
    await tester.pumpAndSettle();
    expect(find.text('EVERY STOP\nCOUNTS.'), findsOneWidget);
    expect(find.text('John Passenger'), findsOneWidget);
    expect(find.text('Jane Passenger'), findsOneWidget);
    await tester.ensureVisible(find.text('MARK NO-SHOW').last);
    await tester.tap(find.text('MARK NO-SHOW').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRM'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('OPEN CHECK-IN'));
    await tester.tap(find.text('OPEN CHECK-IN'));
    await tester.pumpAndSettle();
    expect(find.text('SCAN. VERIFY.\nLET THEM RIDE.'), findsOneWidget);
  });

  testWidgets('Operations navigation opens the route directory', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ZBusApp());
    await tester.enterText(find.byType(TextField).first, 'admin@mut.edu');
    await tester.ensureVisible(find.text('ENTER ZBUS'));
    await tester.tap(find.text('ENTER ZBUS'));
    await tester.pumpAndSettle();
    expect(find.text('ONE USER TABLE.\nEVERY PERSON.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('MANAGE ROUTES'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('MANAGE ROUTES'));
    await tester.pumpAndSettle();
    expect(find.text('LINES THROUGH\nNONG CHOK.'), findsOneWidget);
  });

  for (final width in [390.0, 820.0, 1440.0]) {
    testWidgets('All mockup pages render at $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reservations = createInitialReservations();
      for (final page in ZPage.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ZTheme.dark,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ZPages(
                  key: ValueKey(page),
                  page: page,
                  role: ZRole.admin,
                  selectedTrip: trips[2],
                  selectedReservation: reservations.first,
                  initialOrigin: stops[0],
                  initialDestination: stops[2],
                  reservations: reservations,
                  bookingDraft: const [],
                  tripStarted: false,
                  scanned: false,
                  availableSeats: (trip) => trip.available,
                  go: (_) {},
                  selectTrip: (_, _, _) {},
                  book: (_, _, _) {},
                  cancel: (_) {},
                  cancelBooking: (_) {},
                  checkout: () {},
                  selectReservation: (_) {},
                  onStart: () {},
                  onClose: () {},
                  onScan: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Failed page: $page at $width px',
        );
      }
    });
  }
}
