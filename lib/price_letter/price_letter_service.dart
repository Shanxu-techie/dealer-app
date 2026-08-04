import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/models/result.dart';

abstract class PriceLetterException implements Exception {
  const PriceLetterException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PriceLetterUnavailableException extends PriceLetterException {
  const PriceLetterUnavailableException(super.message);
}

class InvalidPriceLetterDataException extends PriceLetterException {
  const InvalidPriceLetterDataException(super.message);
}

FailureResult<PriceLetterData> _toFailureResult(
  Object error,
  StackTrace stackTrace,
) {
  if (error is PriceLetterException) {
    return FailureResult(
      message: error.message,
      exception: error,
      stackTrace: stackTrace,
    );
  }

  return FailureResult(
    message: 'Failed to load price letter.',
    exception: error,
    stackTrace: stackTrace,
  );
}

class ProductPriceData {
  const ProductPriceData({
    required this.indentPrice,
    required this.sellingPrice,
  });

  final double indentPrice;
  final double sellingPrice;
}

class PriceLetterData {
  const PriceLetterData({
    required this.dealerCode,
    required this.effectiveDate,
    this.ms,
    this.hsd,
  });

  final int dealerCode;
  final DateTime effectiveDate;
  final ProductPriceData? ms;
  final ProductPriceData? hsd;
}

PriceLetterData _mapPriceLetterRows({
  required List<dynamic> rows,
  required int dealerCode,
  required DateTime effectiveDate,
}) {
  ProductPriceData? ms;
  ProductPriceData? hsd;

  for (final row in rows) {
    final product = row['product_name'] as String;

    final price = ProductPriceData(
      indentPrice: (row['indent_price'] as num).toDouble(),
      sellingPrice: (row['fixed_selling_price'] as num).toDouble(),
    );

    switch (product) {
      case 'MS':
        ms = price;
        break;
      case 'HSD':
        hsd = price;
        break;
      default:
        throw InvalidPriceLetterDataException(
          'Unexpected product_name: $product',
        );
    }
  }

  if (ms == null && hsd == null) {
    throw PriceLetterUnavailableException(
      'No price data found for dealer $dealerCode',
    );
  }

  return PriceLetterData(
    dealerCode: dealerCode,
    effectiveDate: effectiveDate,
    ms: ms,
    hsd: hsd,
  );
}

Future<Result<PriceLetterData>> fetchPriceLetterData({
  required SupabaseClient supabase,
  required int dealerCode,
  required DateTime effectiveDate,
}) async {
  try {
    final dateStr = effectiveDate.toIso8601String().split('T').first;

    final rows = await supabase
        .from('dealer_prices')
        .select()
        .eq('dealer_code', dealerCode)
        .eq('effective_date', dateStr);

    return SuccessResult(
      _mapPriceLetterRows(
        rows: rows,
        dealerCode: dealerCode,
        effectiveDate: effectiveDate,
      ),
    );
  } catch (e, stackTrace) {
    return _toFailureResult(e, stackTrace);
  }
}

Future<Result<PriceLetterData>> fetchCurrentPriceLetterData({
  required SupabaseClient supabase,
  required int dealerCode,
}) async {
  try {
    final rows = await supabase
        .from('dealer_prices')
        .select()
        .eq('dealer_code', dealerCode)
        .order('effective_date', ascending: false);

    if (rows.isEmpty) {
      throw PriceLetterUnavailableException(
        'No price data found for dealer $dealerCode',
      );
    }

    final latestDateString = rows.first['effective_date'] as String;

    final latestDate = DateTime.parse(latestDateString);

    final latestRows = rows
        .where((row) => row['effective_date'] == latestDateString)
        .toList();

    return SuccessResult(
      _mapPriceLetterRows(
        rows: latestRows,
        dealerCode: dealerCode,
        effectiveDate: latestDate,
      ),
    );
  } catch (e, stackTrace) {
    return _toFailureResult(e, stackTrace);
  }
}
