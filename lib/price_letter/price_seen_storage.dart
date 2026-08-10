import 'package:dealer_app/shared/models/result.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PriceSeenStorage {
  PriceSeenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _keyPrefix = 'last_seen_effective_date_';

  final FlutterSecureStorage _storage;

  String _keyForDealer(int dealerCode) {
    return '$_keyPrefix$dealerCode';
  }

  Future<Result<DateTime?>> getLastSeenEffectiveDate(int dealerCode) async {
    try {
      final value = await _storage.read(key: _keyForDealer(dealerCode));

      if (value == null) {
        return const SuccessResult(null);
      }

      final effectiveDate = DateTime.tryParse(value);

      if (effectiveDate == null) {
        return FailureResult(
          message: 'Invalid stored effective date for dealer $dealerCode.',
          exception: FormatException(value),
        );
      }

      return SuccessResult(effectiveDate);
    } catch (e, stackTrace) {
      return FailureResult(
        message: 'Failed to read seen state for dealer $dealerCode.',
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Result<void>> markAsSeen({
    required int dealerCode,
    required DateTime effectiveDate,
  }) async {
    try {
      await _storage.write(
        key: _keyForDealer(dealerCode),
        value: effectiveDate.toIso8601String(),
      );

      return const SuccessResult(null);
    } catch (e, stackTrace) {
      return FailureResult(
        message: 'Failed to save seen state for dealer $dealerCode.',
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Result<void>> clear(int dealerCode) async {
    try {
      await _storage.delete(key: _keyForDealer(dealerCode));

      return const SuccessResult(null);
    } catch (e, stackTrace) {
      return FailureResult(
        message: 'Failed to clear seen state for dealer $dealerCode.',
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }
}
