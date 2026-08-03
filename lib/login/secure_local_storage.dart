import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    try {
      return await _storage.containsKey(key: supabasePersistSessionKey);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(key: supabasePersistSessionKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _storage.write(
        key: supabasePersistSessionKey,
        value: persistSessionString,
      );
    } catch (_) {
      // If secure storage fails, the session simply won't persist.
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(key: supabasePersistSessionKey);
    } catch (_) {
      // If secure storage fails, treat the session as removed.
    }
  }
}
