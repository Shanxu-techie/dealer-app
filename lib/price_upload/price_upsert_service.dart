import 'dart:async';
import 'dart:io';

import 'package:dealer_app/price_upload/price_importer_parser.dart';
import 'package:flutter/foundation.dart';
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
            )
            .timeout(const Duration(seconds: 30));

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
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          debugPrint('Price upload batch timed out: $e');
        }

        batchResults.add(
          BatchResult(
            batchNumber: batchResults.length + 1,
            sheet: chunk.first.sheet,
            startRow: chunk.first.rowNumber,
            endRow: chunk.last.rowNumber,
            rowCount: chunk.length,
            success: false,
            errorMessage:
                'The server took too long to respond. Please try again.',
          ),
        );
      } on SocketException catch (e) {
        if (kDebugMode) {
          debugPrint('Price upload batch failed (network): $e');
        }

        batchResults.add(
          BatchResult(
            batchNumber: batchResults.length + 1,
            sheet: chunk.first.sheet,
            startRow: chunk.first.rowNumber,
            endRow: chunk.last.rowNumber,
            rowCount: chunk.length,
            success: false,
            errorMessage:
                'No internet connection. Check your network and try again.',
          ),
        );
      } on PostgrestException catch (e) {
        if (kDebugMode) {
          debugPrint('Price upload batch failed (postgrest): $e');
        }

        batchResults.add(
          BatchResult(
            batchNumber: batchResults.length + 1,
            sheet: chunk.first.sheet,
            startRow: chunk.first.rowNumber,
            endRow: chunk.last.rowNumber,
            rowCount: chunk.length,
            success: false,
            errorMessage: 'Server error while saving this batch.',
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Price upload batch failed: $e');
        }

        batchResults.add(
          BatchResult(
            batchNumber: batchResults.length + 1,
            sheet: chunk.first.sheet,
            startRow: chunk.first.rowNumber,
            endRow: chunk.last.rowNumber,
            rowCount: chunk.length,
            success: false,
            errorMessage: 'Something went wrong while uploading this batch.',
          ),
        );
      }
    }
  }
  return UpsertSummary(totalRows: rows.length, batchResults: batchResults);
}
