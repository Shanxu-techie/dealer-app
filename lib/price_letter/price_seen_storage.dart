import 'package:dealer_app/shared/models/result.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PriceSeenStorage {
  PriceSeenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _keyPrefix = 'last_seen_snapshot_';

  final FlutterSecureStorage _storage;

  String _keyForDealer(int dealerCode) {
    return '$_keyPrefix$dealerCode';
  }

  String _buildSnapshot({
    required DateTime effectiveDate,
    required double? msPrice,
    required double? hsdPrice,
  }) {
    final dateStr = effectiveDate.toIso8601String().split('T').first;
    final msStr = msPrice?.toStringAsFixed(2) ?? 'null';
    final hsdStr = hsdPrice?.toStringAsFixed(2) ?? 'null';

    return '$dateStr|$msStr|$hsdStr';
  }

  Future<Result<bool>> hasUnseenChange({
    required int dealerCode,
    required DateTime effectiveDate,
    required double? msPrice,
    required double? hsdPrice,
  }) async {
    try {
      final currentSnapshot = _buildSnapshot(
        effectiveDate: effectiveDate,
        msPrice: msPrice,
        hsdPrice: hsdPrice,
      );

      final storedSnapshot = await _storage.read(
        key: _keyForDealer(dealerCode),
      );

      if (storedSnapshot == null) {
        await _storage.write(
          key: _keyForDealer(dealerCode),
          value: currentSnapshot,
        );

        return const SuccessResult(false);
      }

      return SuccessResult(storedSnapshot != currentSnapshot);
    } catch (e, stackTrace) {
      return FailureResult(
        message: 'Failed to check seen state for dealer $dealerCode.',
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Result> markAsSeen({
    required int dealerCode,
    required DateTime effectiveDate,
    required double? msPrice,
    required double? hsdPrice,
  }) async {
    try {
      final snapshot = _buildSnapshot(
        effectiveDate: effectiveDate,
        msPrice: msPrice,
        hsdPrice: hsdPrice,
      );

      await _storage.write(key: _keyForDealer(dealerCode), value: snapshot);

      return const SuccessResult(null);
    } catch (e, stackTrace) {
      return FailureResult(
        message: 'Failed to save seen state for dealer $dealerCode.',
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Result> clear(int dealerCode) async {
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
