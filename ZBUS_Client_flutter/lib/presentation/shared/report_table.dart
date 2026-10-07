import 'package:flutter/material.dart';

import 'design_system.dart';

/// The table half of a report: the exact numbers the chart above it summarises.
///
/// Its own widget rather than [UiTable] because a record table reserves an
/// action column, divides the width evenly and has a row per record, and a
/// report has none of those -- its columns belong to the report itself.
///
/// Scrollable sideways for the same reason. Station usage carries a pickup and
/// a dropoff for each of the twelve months, twenty-five columns in all, and
/// squeezing those into the width available would leave none of them readable.
class ZReportTable extends StatelessWidget {
  const ZReportTable({super.key, required this.columns, required this.rows});

  final List<String> columns;
  final List<List<Object?>> rows;

  /// The first column names what is being measured -- a station, a month, a
  /// driver -- and needs room for a name. The rest are counts.
  static const double labelWidth = 200;
  static const double valueWidth = 124;

  /// Each line's horizontal padding. Part of the scroll width: a line is
  /// `2*_pad` wider than the columns it lays out, and forgetting that squeezes
  /// the row to its padding and overflows it by that same amount.
  static const double _pad = 14;

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty || rows.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 2 * _pad + labelWidth + (valueWidth * (columns.length - 1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _line(columns, header: true),
            for (final row in rows) _line(row, header: false),
          ],
        ),
      ),
    );
  }

  Widget _line(List<Object?> cells, {required bool header}) => Container(
    padding: EdgeInsets.symmetric(horizontal: _pad, vertical: header ? 14 : 15),
    // A heavier rule under the header, matching how every other table in the
    // interface separates its labels from its records.
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: header ? ZColors.ink : ZColors.line)),
    ),
    child: Row(
      children: [
        for (var i = 0; i < columns.length; i++)
          SizedBox(
            width: i == 0 ? labelWidth : valueWidth,
            child: Text(
              (i < cells.length ? _show(cells[i]) : '').toUpperCase(),
              textAlign: i == 0 ? TextAlign.start : TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: header
                  ? ZTheme.mono(11, color: ZColors.muted)
                  : const TextStyle(fontSize: 13, height: 1.25),
            ),
          ),
      ],
    ),
  );

  /// Counts are whole numbers in every report, and `12.0` under a column a
  /// person is scanning for `12` reads as a different quantity.
  static String _show(Object? value) {
    if (value == null) return '';
    if (value is double && value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return '$value';
  }
}
