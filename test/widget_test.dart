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
    await tester.ensureVisible(find.text('CONFIRM 1 SEAT'));
    await tester.tap(find.text('CONFIRM 1 SEAT'));
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

    await tester.tap(find.text('ACCOUNT'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Updated Passenger');
    await tester.tap(find.text('FIND A TRIP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('Updated Passenger'), findsWidgets);
  });

  testWidgets('Driver can start a run and open check-in', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ZBusApp());
    await tester.ensureVisible(find.text('DRIVER'));
    await tester.tap(find.text('DRIVER'));
    await tester.ensureVisible(find.text('ENTER ZBUS'));
    await tester.tap(find.text('ENTER ZBUS'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR DAY\nON THE ROAD.'), findsOneWidget);
    await tester.ensureVisible(find.text('START TRIP'));
    await tester.tap(find.text('START TRIP'));
    await tester.pumpAndSettle();
    expect(find.text('EVERY STOP\nCOUNTS.'), findsOneWidget);
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
    await tester.tap(find.text('ADMIN'));
    await tester.ensureVisible(find.text('ENTER ZBUS'));
    await tester.tap(find.text('ENTER ZBUS'));
    await tester.pumpAndSettle();
    expect(find.text('THE NETWORK\nAT A GLANCE.'), findsOneWidget);
    await tester.tap(find.text('ROUTES'));
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
                  tripStarted: false,
                  scanned: false,
                  availableSeats: (trip) => trip.available,
                  go: (_) {},
                  selectTrip: (_, _, _) {},
                  book: (_, _, _) {},
                  cancel: (_) {},
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
