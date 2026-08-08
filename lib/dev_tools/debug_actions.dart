import 'package:dealer_app/login/login_service.dart';
import 'package:dealer_app/price_letter/price_letter_service.dart';
import 'package:dealer_app/services/price_importer_parser.dart';
import 'package:dealer_app/services/price_upsert_service.dart';
import 'package:dealer_app/shared/models/result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DebugActions {
  const DebugActions(this.supabase, this.loginService);

  final SupabaseClient supabase;
  final LoginService loginService;

  static const _dealerCode = 171317;
  static const _otherDealerCode = 171736;
  static const _effectiveDate = '2026-07-27';

  // ---------------------------------------------------------------------------
  // Positive tests
  // ---------------------------------------------------------------------------

  Future<void> testPublisherCanReadDealerPrices() async {
    await _runTest('Publisher - Can Read Dealer Prices', () async {
      final rows = await _getDealerPrices(dealerCode: _dealerCode);

      debugPrint('Dealer Code: $_dealerCode');
      debugPrint('Returned rows: ${rows.length}');

      for (final row in rows) {
        debugPrint(row.toString());
      }
    });
  }

  Future<void> testDealerCanReadOwnPrices() async {
    await _runTest('Dealer - Can Read Own Prices', () async {
      final rows = await _getDealerPrices(
        dealerCode: _otherDealerCode,
        effectiveDate: _effectiveDate,
      );

      debugPrint('Dealer Code: $_otherDealerCode');
      debugPrint('Effective Date: $_effectiveDate');
      debugPrint('Returned rows: ${rows.length}');

      for (final row in rows) {
        debugPrint(row.toString());
      }
    });
  }

  Future<void> testCurrentPriceLetter() async {
    await _runTest('Dealer - Can Read Current Price Letter', () async {
      final result = await fetchCurrentPriceLetterData(
        supabase: supabase,
        dealerCode: _dealerCode,
      );

      switch (result) {
        case SuccessResult(data: final data):
          debugPrint('Dealer: ${data.dealerCode}');
          debugPrint('Date: ${data.effectiveDate}');
          debugPrint('MS: ${data.ms?.sellingPrice}');
          debugPrint('HSD: ${data.hsd?.sellingPrice}');

        case FailureResult(message: final message):
          debugPrint('FAILED: $message');
      }
    });
  }

  Future<void> testImport() async {
    await _runTest('Import Price Letter', () async {
      final bytes = await _loadSamplePriceLetter();

      const parser = PriceImportParser();

      final parseResult = parser.parse(
        bytes,
        effectiveDate: DateTime(2026, 7, 27),
      );

      debugPrint('Parsed rows: ${parseResult.rows.length}');
      debugPrint('Parse errors: ${parseResult.errors.length}');

      final summary = await upsertDealerPrices(supabase, parseResult.rows);

      _printImportSummary(summary);
    });
  }

  Future<void> testGetCurrentUserProfile() async {
    await _runTest('Auth - Get Current User Profile', () async {
      final profile = await loginService.getCurrentUserProfile();

      debugPrint('Profile loaded successfully');
      debugPrint('Role: ${profile['role']}');
      debugPrint('Dealer Code: ${profile['dealer_code']}');
      debugPrint('Name: ${profile['name']}');
    });
  }

  Future<void> testSignOut() async {
    await _runTest('Auth - Sign Out', () async {
      await loginService.signOut();

      final session = supabase.auth.currentSession;

      if (session == null) {
        debugPrint('PASS - Session cleared after sign out');
      } else {
        debugPrint('FAIL - Session still exists after sign out');
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Negative tests
  // ---------------------------------------------------------------------------

  Future<void> testDealerCannotReadOtherDealerPrices() async {
    await _runTest('Dealer - Cannot Read Other Dealer Prices', () async {
      final rows = await _getDealerPrices(
        dealerCode: _dealerCode,
        effectiveDate: _effectiveDate,
      );

      if (rows.isEmpty) {
        debugPrint('PASS - Other dealer data is not accessible');
      } else {
        debugPrint('FAIL - Other dealer data was returned');
        debugPrint('Returned rows: ${rows.length}');

        for (final row in rows) {
          debugPrint(row.toString());
        }
      }
    });
  }

  Future<void> testDealerCannotWritePrices() async {
    await _runTest('Dealer - Cannot Write Dealer Prices', () async {
      try {
        await supabase.from('dealer_prices').insert({
          'dealer_code': 987654321,
          'effective_date': '2099-01-01',
          'product_name': 'RLS_TEST_ONLY',
          'indent_price': 250,
          'fixed_selling_price': 252,
        });

        debugPrint('FAIL - Write succeeded; RLS is too permissive');
      } catch (e) {
        debugPrint('PASS - Write was blocked by RLS');
        debugPrint(e.toString());
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Supabase helpers
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> _getDealerPrices({
    required int dealerCode,
    String? effectiveDate,
  }) async {
    var query = supabase
        .from('dealer_prices')
        .select()
        .eq('dealer_code', dealerCode);

    if (effectiveDate != null) {
      query = query.eq('effective_date', effectiveDate);
    }

    return await query;
  }

  // ---------------------------------------------------------------------------
  // Import helpers
  // ---------------------------------------------------------------------------

  Future<Uint8List> _loadSamplePriceLetter() async {
    final bytes = await rootBundle.load('assets/sample_price_letter.xlsx');

    return bytes.buffer.asUint8List();
  }

  void _printImportSummary(dynamic summary) {
    debugPrint('Total rows: ${summary.totalRows}');
    debugPrint('Successful batches: ${summary.successfulBatches}');
    debugPrint('Failed batches: ${summary.failedBatches}');

    for (final batch in summary.batchResults) {
      debugPrint(
        'Batch ${batch.batchNumber}: '
        'success=${batch.success} '
        'rows=${batch.rowCount} '
        'error=${batch.errorMessage}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Test runner
  // ---------------------------------------------------------------------------

  Future<void> _runTest(String name, Future<void> Function() test) async {
    debugPrint('');
    debugPrint('========== $name ==========');

    try {
      await test();

      debugPrint('========== $name COMPLETE ==========');
    } catch (e, st) {
      debugPrint('========== $name FAILED ==========');
      debugPrint(e.toString());
      debugPrint(st.toString());
    }
  }
}
