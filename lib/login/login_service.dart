import 'package:dealer_app/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginService {
  LoginService({NotificationService? notificationService})
      : _notificationService =
      notificationService ?? NotificationService();

  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
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
    await _notificationService.removeCurrentToken();
    await _supabase.auth.signOut();
  }

  Future<void> signOutAndReturnToLogin(BuildContext context) async {
    await signOut();

    if (!context.mounted) return;

    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
  }
}