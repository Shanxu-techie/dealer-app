import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/models/result.dart';
import 'dealer_summary.dart';

class DealerSearchService {
  final SupabaseClient _supabase;

  DealerSearchService(this._supabase);

  Future<Result<List<DealerSummary>>> getDealers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('dealer_code, name')
          .eq('role', 'dealer')
          .order('dealer_code');
      final List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(
        response,
      );
      final List<DealerSummary> dealers = rows
          .map(DealerSummary.fromMap)
          .toList();

      return SuccessResult(dealers);
    } catch (e, stackTrace) {
      return FailureResult(
        message: e.toString(),
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  List<DealerSummary> filterDealers(List<DealerSummary> dealers, String query) {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return dealers;
    }

    return dealers.where((dealer) {
      return dealer.dealerCode.toString().startsWith(trimmedQuery);
    }).toList();
  }
}
