import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

/// The spreadsheet half of a report export.
///
/// Pure: it returns bytes and writes nothing anywhere. Turning a table into a
/// file format is a detail no screen should have to know about, and keeping it
/// here means a test can decode what came out and read the cells back rather
/// than trusting that the button did something.
class ReportSpreadsheet {
  const ReportSpreadsheet._();

  /// An `.xlsx`: the report's title, what range it covered, then the table.
  ///
  /// The two preamble rows are why there is a blank row before the header. A
  /// file that opened with a fourth line of prose would make the header look
  /// like more prose, and the first thing anybody does with an export is read
  /// the first row to find out what it is.
  static Uint8List build({
    required String title,
    required String dateRange,
    required List<String> columns,
    required List<List<Object?>> rows,
  }) {
    final workbook = Excel.createExcel();
    const sheet = 'Report';

    // The workbook opens with a placeholder sheet; renaming it rather than
    // adding a second one and deleting the first leaves one sheet either way.
    final starter = workbook.getDefaultSheet();
    if (starter != null && starter != sheet) workbook.rename(starter, sheet);

    final emphasis = CellStyle(bold: true);
    _put(workbook, sheet, 0, 0, TextCellValue(title), emphasis);
    _put(workbook, sheet, 0, 1, TextCellValue(dateRange));

    for (var column = 0; column < columns.length; column++) {
      _put(workbook, sheet, column, 3, TextCellValue(columns[column]), emphasis);
    }

    for (var row = 0; row < rows.length; row++) {
      for (var column = 0; column < columns.length; column++) {
        final source = rows[row];
        final cell = _cell(column < source.length ? source[column] : null);
        // An empty cell stays empty rather than being written as a blank
        // string; some spreadsheet readers treat "" differently from nothing.
        if (cell == null) continue;
        _put(workbook, sheet, column, row + 4, cell);
      }
    }

    final encoded = workbook.encode();
    if (encoded == null) {
      throw StateError('The report table could not be written to a spreadsheet.');
    }
    return Uint8List.fromList(encoded);
  }

  static void _put(
    Excel workbook,
    String sheet,
    int column,
    int row,
    CellValue value, [
    CellStyle? style,
  ]) => workbook.updateCell(
    sheet,
    CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
    value,
    cellStyle: style,
  );

  /// Numbers stay numbers so the columns sum in Excel; everything else is text.
  ///
  /// A count written as a string would sort as text and refuse to total, which
  /// is the entire reason somebody asked for a spreadsheet instead of a
  /// screenshot.
  static CellValue? _cell(Object? value) => switch (value) {
    null => null,
    bool() => BoolCellValue(value),
    int() => IntCellValue(value),
    double() => DoubleCellValue(value),
    _ => TextCellValue('$value'),
  };
}

/// Where an exported report lands.
///
/// The one part of an export that needs a platform plugin, so it sits behind an
/// interface: a test hands the screen a fake and asserts on the bytes it was
/// given instead of on whatever a save dialog did with them.
abstract class ReportFileWriter {
  /// Writes [bytes] as a `.png`.
  Future<void> picture(String name, Uint8List bytes);

  /// Writes [bytes] as a `.xlsx`.
  Future<void> spreadsheet(String name, Uint8List bytes);
}

/// The real writer, backed by `file_saver`: a save dialog on desktop and
/// Android, a download on the web.
///
/// The extension and MIME type live here rather than at the call site because
/// a picture and a spreadsheet are the two things a report becomes, and the
/// caller should not have to know that one of them is `.xlsx`.
class FileSaverReportWriter implements ReportFileWriter {
  const FileSaverReportWriter();

  @override
  Future<void> picture(String name, Uint8List bytes) =>
      _write(name, bytes, 'png', MimeType.png);

  @override
  Future<void> spreadsheet(String name, Uint8List bytes) =>
      _write(name, bytes, 'xlsx', MimeType.microsoftExcel);

  Future<void> _write(
    String name,
    Uint8List bytes,
    String extension,
    MimeType type,
  ) => FileSaver.instance.saveFile(
    name: name,
    bytes: bytes,
    fileExtension: extension,
    mimeType: type,
  );
}
