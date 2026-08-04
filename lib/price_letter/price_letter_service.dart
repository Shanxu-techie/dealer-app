import 'package:supabase_flutter/supabase_flutter.dart';

class PriceLetterUnavailableException implements Exception {
  const PriceLetterUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
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
        throw StateError('Unexpected product_name: $product');
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

Future<PriceLetterData> fetchPriceLetterData({
  required SupabaseClient supabase,
  required int dealerCode,
  required DateTime effectiveDate,
}) async {
  final dateStr = effectiveDate.toIso8601String().split('T').first;

  final rows = await supabase
      .from('dealer_prices')
      .select()
      .eq('dealer_code', dealerCode)
      .eq('effective_date', dateStr);

  return _mapPriceLetterRows(
    rows: rows,
    dealerCode: dealerCode,
    effectiveDate: effectiveDate,
  );
}

Future<PriceLetterData> fetchCurrentPriceLetterData({
  required SupabaseClient supabase,
  required int dealerCode,
}) async {
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

  return _mapPriceLetterRows(
    rows: latestRows,
    dealerCode: dealerCode,
    effectiveDate: latestDate,
  );
}