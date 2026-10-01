import 'package:flutter/material.dart';

import '../presentation/features/auth/auth_page.dart';
import '../presentation/features/account/account_page.dart';
import '../presentation/features/booking/booking_page.dart';
import '../presentation/features/bookings/bookings_page.dart';
import '../presentation/features/driver/driver_schedule_page.dart';
import '../presentation/features/driver/current_trip_page.dart';
import '../presentation/features/driver/check_in_page.dart';
import '../presentation/features/reports/reports_page.dart';
import '../presentation/features/user_management/user_management_page.dart';
import '../presentation/features/employee_management/employee_management_page.dart';
import '../presentation/features/department_management/department_management_page.dart';
import '../presentation/features/position_management/position_management_page.dart';
import '../presentation/features/station_management/station_management_page.dart';
import '../presentation/features/vehicle_management/vehicle_management_page.dart';
import '../presentation/features/route_management/route_management_page.dart';
import '../presentation/features/schedule_management/schedule_management_page.dart';

/// UI navigation only. Replace empty page constructors at the composition root
/// with presenter bindings; add authentication/authorization in your router.
enum AppPage {
  login,
  register,
  booking,
  bookings,
  account,
  driverSchedule,
  currentTrip,
  checkIn,
  user,
  employee,
  department,
  position,
  station,
  vehicle,
  route,
  schedule,
  reports,
}

extension AppPageInfo on AppPage {
  String get label => switch (this) {
    AppPage.login => 'Login',
    AppPage.register => 'Register',
    AppPage.booking => 'Booking',
    AppPage.bookings => 'View booked',
    AppPage.account => 'My account',
    AppPage.driverSchedule => 'My driving schedule',
    AppPage.currentTrip => 'Current trip',
    AppPage.checkIn => 'QR check-in',
    AppPage.user => 'Manage users',
    AppPage.employee => 'Manage employees',
    AppPage.department => 'Manage departments',
    AppPage.position => 'Manage positions',
    AppPage.station => 'Manage stations',
    AppPage.vehicle => 'Manage vehicles',
    AppPage.route => 'Manage routes',
    AppPage.schedule => 'Manage schedules',
    AppPage.reports => 'Statistic reports',
  };
  String get group => switch (this) {
    AppPage.login => 'User',
    AppPage.register => 'User',
    AppPage.booking => 'User',
    AppPage.bookings => 'User',
    AppPage.account => 'User',
    AppPage.driverSchedule => 'Driver',
    AppPage.currentTrip => 'Driver',
    AppPage.checkIn => 'Driver',
    AppPage.user => 'Management',
    AppPage.employee => 'Management',
    AppPage.department => 'Management',
    AppPage.position => 'Management',
    AppPage.station => 'Route',
    AppPage.vehicle => 'Management',
    AppPage.route => 'Route',
    AppPage.schedule => 'Route',
    AppPage.reports => 'Statistic',
  };
  Widget get screen => switch (this) {
    AppPage.login => const AuthPage(),
    AppPage.register => const AuthPage(register: true),
    AppPage.booking => const BookingPage(),
    AppPage.bookings => const BookingsPage(),
    AppPage.account => const AccountPage(),
    AppPage.driverSchedule => const DriverSchedulePage(),
    AppPage.currentTrip => const CurrentTripPage(),
    AppPage.checkIn => const CheckInPage(),
    AppPage.user => const UserManagementPage(),
    AppPage.employee => const EmployeeManagementPage(),
    AppPage.department => const DepartmentManagementPage(),
    AppPage.position => const PositionManagementPage(),
    AppPage.station => const StationManagementPage(),
    AppPage.vehicle => const VehicleManagementPage(),
    AppPage.route => const RouteManagementPage(),
    AppPage.schedule => const ScheduleManagementPage(),
    AppPage.reports => const ReportsPage(),
  };
}
