import 'package:flutter/material.dart';

/// Shared content frame for every feature page.
///
/// Feature pages are editorial and long, so they always scroll; padding tightens
/// on phones and the content is capped so a wide display does not stretch text
/// lines to the bezel. The application shell and the layout tests both use this
/// widget so tests exercise the real host instead of a copy of it.
class PageHost extends StatelessWidget {
  const PageHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        mobile ? 20 : 42,
        mobile ? 28 : 44,
        mobile ? 20 : 50,
        100,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: child,
        ),
      ),
    );
  }
}