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
      'No price data found for dealer $dealerCode on '
      '$dateStr',
    );
  }

  return PriceLetterData(
    dealerCode: dealerCode,
    effectiveDate: effectiveDate,
    ms: ms,
    hsd: hsd,
  );
}
