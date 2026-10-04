import 'package:flutter/material.dart';

import 'design_system.dart';

/// Shared page chrome; children remain independently reusable feature widgets.
///
/// [index] and [kicker] feed the ZPageHeader breadcrumb, [title] carries the
/// oversized display headline (line breaks are preserved) and [description] the
/// muted standfirst. Omitting them falls back to the navigation section so no
/// page can render a bare, unlabelled heading.
class WorkflowPage extends StatelessWidget {
  const WorkflowPage({
    super.key,
    required this.title,
    required this.section,
    this.index,
    this.kicker,
    this.description = '',
    this.action,
    required this.children,
  });
  final String title, section;
  final String? index, kicker;
  final String description;
  final Widget? action;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ZPageHeader(
        index: index ?? section,
        kicker: kicker ?? section,
        title: title,
        description: description,
        action: action,
      ),
      for (final child in children)
        Padding(padding: const EdgeInsets.only(bottom: 24), child: child),
    ],
  );
}