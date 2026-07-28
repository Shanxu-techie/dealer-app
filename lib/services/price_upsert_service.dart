import 'package:dealer_app/services/price_importer_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BatchResult {
  final int batchNumber;

  final String sheet;

  /// First spreadsheet row in this batch (inclusive, 1-based).
  final int startRow;

  /// Last spreadsheet row in this batch (inclusive, 1-based).
  final int endRow;

  final int rowCount;
  final bool success;
  final String? errorMessage;

  const BatchResult({
    required this.batchNumber,
    required this.sheet,
    required this.startRow,
    required this.endRow,
    required this.rowCount,
    required this.success,
    this.errorMessage,
  });
}

class UpsertSummary {
  const UpsertSummary({required this.totalRows, required this.batchResults});

  final int totalRows;
  final List<BatchResult> batchResults;

  int get successfulBatches =>
      batchResults.where((batch) => batch.success).length;

  int get failedBatches => batchResults.where((batch) => !batch.success).length;

  bool get wasAttempted => batchResults.isNotEmpty;

  bool get allSucceeded => wasAttempted && failedBatches == 0;
}

Map<String, dynamic> _toMap(DealerPriceRow row) {
  return {
    'dealer_code': row.dealerCode,
    'effective_date': row.effectiveDate.toIso8601String().split('T').first,
    'product_name': row.product,
    'indent_price': row.indentPrice,
    'fixed_selling_price': row.fixedSellingPrice,
  };
}

Future<UpsertSummary> upsertDealerPrices(
  SupabaseClient supabase,
  List<DealerPriceRow> rows, {
  int batchSize = 500,
}) async {
  if (batchSize <= 0) {
    throw ArgumentError.value(
      batchSize,
      'batchSize',
      'batchSize must be greater than 0.',
    );
  }

  if (rows.isEmpty) {
    return const UpsertSummary(totalRows: 0, batchResults: []);
  }

  final batchResults = <BatchResult>[];
  final rowsBySheet = <String, List<DealerPriceRow>>{};

  for (final row in rows) {
    rowsBySheet.putIfAbsent(row.sheet, () => []).add(row);
  }

  for (final sheetRows in rowsBySheet.values) {
    for (var start = 0; start < sheetRows.length; start += batchSize) {
      final end = (start + batchSize < sheetRows.length)
          ? start + batchSize
          : sheetRows.length;

      final chunk = sheetRows.sublist(start, end);

      assert(chunk.every((row) => row.sheet == chunk.first.sheet));

      final payload = chunk.map(_toMap).toList();

      try {
        await supabase
            .from('dealer_prices')
            .upsert(
              payload,
              onConflict: 'dealer_code,effective_date,product_name',
            );

        batchResults.add(
          BatchResult(
            batchNumber: batchResults.length + 1,
            sheet: chunk.first.sheet,
            startRow: chunk.first.rowNumber,
            endRow: chunk.last.rowNumber,
            rowCount: chunk.length,
            success: true,
          ),
        );
      } on PostgrestException catch (e) {
        batchResults.add(
          BatchResult(
            batchNumber: batchResults.length + 1,
            sheet: chunk.first.sheet,
            startRow: chunk.first.rowNumber,
            endRow: chunk.last.rowNumber,
            rowCount: chunk.length,
            success: false,
            errorMessage: e.message,
          ),
        );
      } catch (e) {
        batchResults.add(
          BatchResult(
            batchNumber: batchResults.length + 1,
            sheet: chunk.first.sheet,
            startRow: chunk.first.rowNumber,
            endRow: chunk.last.rowNumber,
            rowCount: chunk.length,
            success: false,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  return UpsertSummary(totalRows: rows.length, batchResults: batchResults);
}
