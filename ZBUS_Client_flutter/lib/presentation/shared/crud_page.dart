import 'package:flutter/material.dart';

import 'design_system.dart';

/// Search text is forwarded unchanged. Implement filtering/debouncing/pagination
/// outside the widget and pass the resulting rows to the feature table.
///
/// Every state a list can be in is a parameter rather than something the widget
/// works out, because only the controller knows whether a blank table means "no
/// rows yet", "no rows match" or "the request failed". The defaults reproduce the
/// original empty-by-default behaviour, so a layout preview still renders.
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
    this.loading = false,
    this.hasRows = false,
    this.error,
    this.notice,
    this.onRetry,
    this.onDismiss,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage = 'Records will appear here once there are any.',
  });

  final String title, description;
  final Widget table;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final VoidCallback? onAdd;
  final String index, searchLabel, sectionNumber, sectionTitle;
  final String? kicker;

  /// The first load is in flight.
  ///
  /// A refresh deliberately leaves this false: the existing rows stay visible
  /// while they are known to be stale, which beats blanking the screen.
  final bool loading;

  /// Whether [table] currently has anything to show.
  ///
  /// This is what separates "still loading" from "loaded, and empty", and it is a
  /// parameter because the controller counts the rows, not the table.
  final bool hasRows;

  /// A failed load or write. Shown as a banner, and as the whole body when there
  /// are no rows to fall back on.
  final String? error;

  /// A successful write. Shown as a banner until dismissed.
  final String? notice;

  final VoidCallback? onRetry, onDismiss;
  final String emptyTitle, emptyMessage;

  @override
  Widget build(BuildContext context) {
    // An error with rows behind it is a warning about a write, not about the
    // list: the rows are still real and still worth showing.
    final body = switch ((loading, hasRows, error)) {
      (true, false, _) => const ZEmpty(
        'Loading',
        'Fetching records from the server.',
      ),
      (_, false, final String message) => ZEmpty(
        emptyTitle,
        message,
        action: onRetry == null
            ? null
            : ZButton('Try again', icon: Icons.refresh, onPressed: onRetry),
      ),
      _ => table,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ZPageHeader(
          index: index,
          kicker: kicker ?? title,
          title: title,
          description: description,
          // Disabled while the first load runs, so Add cannot open a dialog over
          // an empty list whose assignment dropdowns have not loaded.
          action: onAdd == null || loading
              ? null
              : ZButton('Add', icon: Icons.add, onPressed: onAdd),
        ),
        ZSearch(
          hint: searchLabel,
          controller: searchController,
          onChanged: onSearchChanged,
        ),
        const ZGap(34),
        ZSectionTitle(
          sectionNumber,
          sectionTitle,
          trailing: loading
              ? Text(
                  'Loading',
                  style: ZTheme.mono(11, color: ZColors.muted),
                )
              : null,
        ),
        if (error != null && hasRows) ...[
          ZNotice(
            'Could not complete that',
            error!,
            color: ZColors.accent,
            icon: Icons.error_outline,
          ),
          const ZGap(18),
        ],
        if (notice != null) ...[
          ZNotice(
            'Done',
            notice!,
            color: ZColors.success,
            icon: Icons.check_circle_outline,
          ),
          const ZGap(18),
        ],
        body,
        if (notice != null && onDismiss != null) ...[
          const ZGap(14),
          Align(
            alignment: Alignment.centerLeft,
            child: ZButton(
              'Dismiss',
              secondary: true,
              compact: true,
              onPressed: onDismiss,
            ),
          ),
        ],
      ],
    );
  }
}
