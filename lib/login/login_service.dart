import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select('id, dealer_code, role, name')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        throw Exception(
          'Profile not found or not accessible for the authenticated user.',
        );
      }

      return profile;
    } on PostgrestException catch (e) {
      throw Exception('Failed to load user profile: ${e.message}');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    debugPrint(
      'Current session after signOut: ${_supabase.auth.currentSession}',
    );
  }
}
