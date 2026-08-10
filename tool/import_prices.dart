import 'dart:io';

import 'package:dealer_app/price_upload/price_importer_parser.dart';
Future<void> main() async {
  final bytes = await File('data/sample_price_letter.xlsx').readAsBytes();
  final parser = PriceImportParser();
  final result = parser.parse(
    bytes,
    effectiveDate: DateTime(2026, 7, 27),
  );
  print('Parsed rows: ${result.rows.length}');
  print('Errors: ${result.errors.length}');
  for (final error in result.errors) {
    print(error);
  }
  for (final row in result.rows.take(3)) {
    print(
      '${row.product} | ${row.dealerCode} | '
          '${row.indentPrice} | ${row.fixedSellingPrice} | '
          '${row.effectiveDate}',
    );
  }
}