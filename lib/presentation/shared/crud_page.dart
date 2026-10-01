import 'package:flutter/material.dart';

import 'design_system.dart';

/// Search text is forwarded unchanged. Implement filtering/debouncing/pagination
/// outside the widget and pass the resulting rows to the feature table.
class CrudPage extends StatelessWidget {
  const CrudPage({
    super.key,
    required this.title,
    required this.table,
    this.onSearchChanged,
    this.onAdd,
    this.searchController,
    this.description = '',
  });
  final String title, description;
  final Widget table;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ZPageHeader(
        index: 'MANAGEMENT',
        kicker: title,
        title: title,
        description: description,
        action: ZButton('Add', icon: Icons.add, onPressed: onAdd),
      ),
      TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Search ${title.replaceFirst('Manage ', '').toLowerCase()}',
          prefixIcon: const Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 24),
      table,
    ],
  );
}
