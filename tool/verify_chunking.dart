import 'dart:io';

import 'package:dealer_app/services/price_importer_parser.dart';

Future<void> main() async {
  final bytes = await File('data/sample_price_letter.xlsx').readAsBytes();

  final parser = PriceImportParser();

  final result = parser.parse(
    bytes,
    effectiveDate: DateTime(2026, 7, 27),
  );

  print('=== Parse Summary ===');
  print('Parsed rows: ${result.rows.length}');
  print('Errors: ${result.errors.length}');

  if (result.errors.isNotEmpty) {
    print('\nErrors:');
    for (final error in result.errors) {
      print(error);
    }
  }

  print('\n=== Chunk Verification ===');

  const batchSize = 3;

  final rowsBySheet = <String, List<DealerPriceRow>>{};

  // Group rows by sheet while preserving insertion order.
  for (final row in result.rows) {
    rowsBySheet.putIfAbsent(row.sheet, () => []).add(row);
  }

  var batchNumber = 1;

  for (final entry in rowsBySheet.entries) {
    final sheet = entry.key;
    final sheetRows = entry.value;

    print('\nSheet: $sheet (${sheetRows.length} rows)');

    for (var start = 0; start < sheetRows.length; start += batchSize) {
      final end = (start + batchSize < sheetRows.length)
          ? start + batchSize
          : sheetRows.length;

      final chunk = sheetRows.sublist(start, end);

      assert(chunk.every((row) => row.sheet == chunk.first.sheet));

      print(
        'Batch $batchNumber'
            ' | Sheet: ${chunk.first.sheet}'
            ' | Rows: ${chunk.first.rowNumber}-${chunk.last.rowNumber}'
            ' | Count: ${chunk.length}',
      );

      batchNumber++;
    }
  }
}