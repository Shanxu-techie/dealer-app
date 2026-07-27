import 'dart:typed_data';

import 'package:excel/excel.dart';

class DealerPriceRow {
  final int dealerCode;
  final String product;
  final double indentPrice;
  final double fixedSellingPrice;
  final DateTime effectiveDate;

  const DealerPriceRow({
    required this.dealerCode,
    required this.product,
    required this.indentPrice,
    required this.fixedSellingPrice,
    required this.effectiveDate,
  });
}

class ParseError {
  final String sheet;
  final int rowNumber;
  final String message;

  const ParseError({
    required this.sheet,
    required this.rowNumber,
    required this.message,
  });

  @override
  String toString() => '$sheet - Row $rowNumber: $message';
}

class ParseResult {
  final List<DealerPriceRow> rows;
  final List<ParseError> errors;

  const ParseResult({required this.rows, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
}

class _Columns {
  static const dealerCode = 'CODE';
  static const indentPrice = 'Indent Value - Sold To';
  static const fixedSellingPrice = 'Fixed Selling Price';
}

class PriceImportParser {
  const PriceImportParser();

  double _roundPrice(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  ParseResult parse(Uint8List bytes, {required DateTime effectiveDate}) {
    final rows = <DealerPriceRow>[];
    final errors = <ParseError>[];

    late final Excel excel;

    try {
      excel = Excel.decodeBytes(bytes);
    } on Exception catch (e) {
      errors.add(
        ParseError(
          sheet: 'Workbook',
          rowNumber: 0,
          message: 'Failed to read workbook: $e',
        ),
      );

      return ParseResult(rows: rows, errors: errors);
    }

    if (excel.tables.containsKey('MS')) {
      try {
        _parseSheet(
          sheet: excel.tables['MS']!,
          product: 'MS',
          effectiveDate: effectiveDate,
          rows: rows,
          errors: errors,
        );
      } on Exception catch (e) {
        errors.add(
          ParseError(sheet: 'MS', rowNumber: 0, message: e.toString()),
        );
      }
    } else {
      errors.add(
        const ParseError(
          sheet: 'Workbook',
          rowNumber: 0,
          message: 'Worksheet "MS" not found.',
        ),
      );
    }

    if (excel.tables.containsKey('HSD')) {
      try {
        _parseSheet(
          sheet: excel.tables['HSD']!,
          product: 'HSD',
          effectiveDate: effectiveDate,
          rows: rows,
          errors: errors,
        );
      } on Exception catch (e) {
        errors.add(
          ParseError(sheet: 'HSD', rowNumber: 0, message: e.toString()),
        );
      }
    } else {
      errors.add(
        const ParseError(
          sheet: 'Workbook',
          rowNumber: 0,
          message: 'Worksheet "HSD" not found.',
        ),
      );
    }

    return ParseResult(rows: rows, errors: errors);
  }

  void _parseSheet({
    required Sheet sheet,
    required String product,
    required List<DealerPriceRow> rows,
    required List<ParseError> errors,
    required DateTime effectiveDate,
  }) {
    final columns = _findColumnIndexes(sheet);

    // Skip header row (row 0)
    for (var rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
      final row = sheet.rows[rowIndex];

      final dealerCodeCell =
          row[columns[_Columns.dealerCode]!]?.value?.toString().trim() ?? '';

      // Skip completely blank dealer codes
      if (dealerCodeCell.isEmpty) {
        continue;
      }

      final dealerCode = int.tryParse(dealerCodeCell);

      if (dealerCode == null) {
        errors.add(
          ParseError(
            sheet: sheet.sheetName,
            rowNumber: rowIndex + 1,
            message: 'Invalid dealer code: "$dealerCodeCell".',
          ),
        );
        continue;
      }

      final indentPriceCell =
          row[columns[_Columns.indentPrice]!]?.value?.toString().trim() ?? '';

      final indentPrice = double.tryParse(indentPriceCell);

      if (indentPrice == null) {
        errors.add(
          ParseError(
            sheet: sheet.sheetName,
            rowNumber: rowIndex + 1,
            message: 'Invalid indent price: "$indentPriceCell".',
          ),
        );
        continue;
      }

      final fixedSellingPriceCell =
          row[columns[_Columns.fixedSellingPrice]!]?.value?.toString().trim() ??
          '';

      final fixedSellingPrice = double.tryParse(fixedSellingPriceCell);

      if (fixedSellingPrice == null) {
        errors.add(
          ParseError(
            sheet: sheet.sheetName,
            rowNumber: rowIndex + 1,
            message: 'Invalid fixed selling price: "$fixedSellingPriceCell".',
          ),
        );
        continue;
      }

      rows.add(
        DealerPriceRow(
          dealerCode: dealerCode,
          product: product,
          indentPrice: _roundPrice(indentPrice),
          fixedSellingPrice: _roundPrice(fixedSellingPrice),
          effectiveDate: effectiveDate,
        ),
      );
    }
  }

  String _normalizeHeader(String value) => value.trim().toLowerCase();

  Map<String, int> _findColumnIndexes(Sheet sheet) {
    if (sheet.rows.isEmpty) {
      throw Exception('Worksheet "${sheet.sheetName}" is empty.');
    }

    final header = sheet.rows.first;
    final indexes = <String, int>{};

    for (var i = 0; i < header.length; i++) {
      final value = _normalizeHeader(header[i]?.value?.toString() ?? '');

      if (value == _normalizeHeader(_Columns.dealerCode)) {
        indexes[_Columns.dealerCode] = i;
      } else if (value == _normalizeHeader(_Columns.indentPrice)) {
        indexes[_Columns.indentPrice] = i;
      } else if (value == _normalizeHeader(_Columns.fixedSellingPrice)) {
        indexes[_Columns.fixedSellingPrice] = i;
      }
    }

    for (final requiredColumn in [
      _Columns.dealerCode,
      _Columns.indentPrice,
      _Columns.fixedSellingPrice,
    ]) {
      if (!indexes.containsKey(requiredColumn)) {
        throw Exception(
          'Worksheet "${sheet.sheetName}" is missing required column "$requiredColumn".',
        );
      }
    }

    return indexes;
  }
}
