import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceTokenService {
  DeviceTokenService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<void> registerToken(String token) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw StateError(
        'Cannot register device token without an authenticated user.',
      );
    }

    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
        ? 'ios'
        : null;

    if (platform == null) {
      throw UnsupportedError(
        'Device token registration is only supported on Android and iOS.',
      );
    }

    await _supabase.from('device_tokens').upsert({
      'user_id': user.id,
      'token': token,
      'platform': platform,
    }, onConflict: 'user_id,token');
  }

  Future<bool> removeToken(String token) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final deletedRows = await _supabase
        .from('device_tokens')
        .delete()
        .eq('user_id', user.id)
        .eq('token', token)
        .select('id');

    return deletedRows.isNotEmpty;
  }
}
