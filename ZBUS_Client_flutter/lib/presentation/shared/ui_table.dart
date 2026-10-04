import 'package:flutter/material.dart';

import 'design_system.dart';

/// Width of the trailing action cell: the gap before it, plus the two icon
/// buttons and the space between them.
///
/// Named rather than written inline twice, because the header and the rows have
/// to reserve exactly the same width, and the two buttons alone are wider than
/// the cell used to allow — which overflowed on every device, not only in a
/// narrow test surface. The button size comes from the button itself rather than
/// a literal so the two cannot drift apart.
const double _kActionGap = 12;
const double _kActionSpacing = 8;
const double _kActionsWidth =
    _kActionGap + (kIconActionSize * 2) + _kActionSpacing;

/// Presentation data only. Map your application results into named cells.
/// Keep record IDs in callback closures; never use a displayed name as a key.
class UiTableRow {
  const UiTableRow({
    required this.cells,
    this.onEdit,
    this.onDelete,
    this.actions,
  });
  final Map<String, String> cells;
  final VoidCallback? onEdit, onDelete;
  final Widget? actions;
}

/// Data grid built from the ZBus primitives rather than Material's DataTable:
/// hairline row separators, a heavy header rule, mono column labels and a hover
/// wash. No fetching, sorting or filtering occurs here; pass prepared rows.
class UiTable extends StatelessWidget {
  const UiTable({
    super.key,
    required this.columns,
    this.rows = const [],
    this.emptyLabel = 'No records yet',
    this.showActions = true,
    this.statusColumn = 'Status',
  });
  final List<String> columns;
  final List<UiTableRow> rows;
  final String emptyLabel;
  final bool showActions;
  final String? statusColumn;

  /// The action column is only reserved when at least one row can act, so
  /// read-only grids do not end with a permanently empty column.
  bool get _actionsVisible => showActions &&
      rows.any((r) => r.actions != null || r.onEdit != null || r.onDelete != null);

  bool _isStatus(String column) => statusColumn != null && column == statusColumn;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return ZEmpty(emptyLabel, '');
    final narrow = MediaQuery.sizeOf(context).width < 750;
    final actions = _actionsVisible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!narrow) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ZColors.ink)),
            ),
            child: Row(
              children: [
                for (final column in columns)
                  Expanded(child: ZLabel(column)),
                if (actions) const SizedBox(width: _kActionsWidth),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            _HoverRow(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
                child: Row(
                  children: [
                    for (final column in columns)
                      Expanded(
                        child: _cell(column, rows[i], _isStatus(column)),
                      ),
                    if (actions) ...[
                      const SizedBox(width: _kActionGap),
                      SizedBox(width: _kActionsWidth - _kActionGap, child: _actions(rows[i])),
                    ],
                  ],
                ),
              ),
            ),
        ] else
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 26,
                    runSpacing: 14,
                    children: [
                      for (final column in columns)
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 96),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ZLabel(column),
                              const SizedBox(height: 6),
                              _cell(column, row, _isStatus(column)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (actions) ...[const ZGap(16), _actions(row)],
                ],
              ),
            ),
        const ZRule(),
      ],
    );
  }

  Widget _cell(String column, UiTableRow row, bool status) {
    final value = row.cells[column] ?? '—';
    if (status && value.isNotEmpty) return ZStatus(value);
    return Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _actions(UiTableRow row) {
    if (row.actions != null) return row.actions!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZIconAction(
          icon: Icons.edit_outlined,
          onPressed: row.onEdit,
          tooltip: 'Edit',
        ),
        const SizedBox(width: _kActionSpacing),
        ZIconAction(
          icon: Icons.delete_outline,
          onPressed: row.onDelete,
          tooltip: 'Delete',
          danger: true,
        ),
      ],
    );
  }
}

/// Row hover is presentation-only state and deliberately kept out of the data
/// model; the wash replaces Material's circular ink splash.
class _HoverRow extends StatefulWidget {
  const _HoverRow({required this.child});
  final Widget child;
  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 130);
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: duration,
        decoration: BoxDecoration(
          color: hover ? ZColors.surface : Colors.transparent,
          border: const Border(bottom: BorderSide(color: ZColors.line)),
        ),
        child: widget.child,
      ),
    );
  }
}