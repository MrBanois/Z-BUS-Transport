import 'package:flutter/material.dart';

import 'app/auth_controller.dart';
import 'zbus_app.dart';

/// The composition root.
///
/// The controller is created here so it outlives every widget and can be reused
/// if a session is ever persisted across launches. It has no knowledge of the
/// URL scheme; that is configured at build time with
/// `--dart-define=ZBUS_API=http://host:port`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ZBusApp(auth: AuthController()));
}
