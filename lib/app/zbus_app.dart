import 'package:flutter/material.dart';

import '../presentation/shared/theme.dart';
import 'app_page.dart';

class ZBusApp extends StatelessWidget {
  const ZBusApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ZBus Transport',
    debugShowCheckedModeBanner: false,
    theme: ZTheme.dark,
    home: const ZBusShell(),
  );
}

/// Navigation is the only state in the scaffold. Business actions stay disabled
/// until the application layer supplies their callbacks; there is no demo login.
class ZBusShell extends StatefulWidget {
  const ZBusShell({super.key});
  @override
  State<ZBusShell> createState() => _ZBusShellState();
}

class _ZBusShellState extends State<ZBusShell> {
  AppPage page = AppPage.booking;
  Widget navigation({bool drawer = false}) => Material(
    color: ZColors.surface,
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('ZBUS', style: ZTheme.display(40)),
          const SizedBox(height: 24),
          for (final group in [
            'User',
            'Driver',
            'Management',
            'Route',
            'Statistic',
          ]) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                group.toUpperCase(),
                style: ZTheme.mono(12, color: ZColors.accent),
              ),
            ),
            for (final entry in AppPage.values.where((p) => p.group == group))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.label),
                selected: page == entry,
                onTap: () {
                  setState(() => page = entry);
                  if (drawer) Navigator.of(context).pop();
                },
              ),
          ],
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1080;
    return Scaffold(
      appBar: desktop ? null : AppBar(title: Text(page.label)),
      drawer: desktop ? null : Drawer(child: navigation(drawer: true)),
      body: Row(
        children: [
          if (desktop) SizedBox(width: 260, child: navigation()),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                key: ValueKey(page),
                padding: EdgeInsets.all(desktop ? 40 : 20),
                child: page.screen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
