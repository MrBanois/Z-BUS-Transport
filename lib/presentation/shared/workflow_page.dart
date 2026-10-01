import 'package:flutter/material.dart';

import 'design_system.dart';

/// Shared page chrome; children remain independently reusable feature widgets.
class WorkflowPage extends StatelessWidget {
  const WorkflowPage({
    super.key,
    required this.title,
    required this.section,
    required this.children,
  });
  final String title, section;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ZPageHeader(
        index: section,
        kicker: section,
        title: title,
        description: '',
      ),
      for (final child in children)
        Padding(padding: const EdgeInsets.only(bottom: 24), child: child),
    ],
  );
}
