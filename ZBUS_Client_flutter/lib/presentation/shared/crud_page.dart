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
    this.index = '03 / MANAGEMENT',
    this.kicker,
    this.searchLabel = 'Search',
    this.sectionNumber = '01',
    this.sectionTitle = 'Records',
  });
  final String title, description;
  final Widget table;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final VoidCallback? onAdd;
  final String index, searchLabel, sectionNumber, sectionTitle;
  final String? kicker;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ZPageHeader(
        index: index,
        kicker: kicker ?? title,
        title: title,
        description: description,
        action: onAdd == null
            ? null
            : ZButton('Add', icon: Icons.add, onPressed: onAdd),
      ),
      ZSearch(
        hint: searchLabel,
        controller: searchController,
        onChanged: onSearchChanged,
      ),
      const ZGap(34),
      ZSectionTitle(sectionNumber, sectionTitle),
      table,
    ],
  );
}