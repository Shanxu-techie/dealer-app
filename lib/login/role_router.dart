import 'package:dealer_app/dealer_search/dealer_search_page.dart';
import 'package:dealer_app/dealer_search/dealer_search_service.dart';
import 'package:dealer_app/login/login_service.dart';
import 'package:dealer_app/price_letter/price_letter_page.dart';
import 'package:dealer_app/shared/models/app_user_role.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  late Future<Map<String, dynamic>> _profileFuture;
  final LoginService _loginService = LoginService();

  @override
  void initState() {
    super.initState();
    _profileFuture = _loginService.getCurrentUserProfile();
  }

  void _retry() {
    setState(() {
      _profileFuture = _loginService.getCurrentUserProfile();
    });
  }

  Widget _destinationFor(Map<String, dynamic> profile) {
    final role = (profile['role'] as String? ?? '').toLowerCase();
    switch (role) {
      case 'dealer':
        return PriceLetterPage(
          dealerCode: profile['dealer_code'] as int,
          dealerName: profile['name'] as String?,
          supabase: Supabase.instance.client,
          role: AppUserRole.dealer,
        );
      case 'publisher':
        return DealerSearchPage(
          service: DealerSearchService(Supabase.instance.client),
        );
      default:
        throw Exception('Unsupported user role: $role');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        Object? error = snapshot.error;
        Widget? destination;

        if (error == null && snapshot.hasData) {
          try {
            destination = _destinationFor(snapshot.data!);
          } catch (e, st) {
            debugPrint('Role routing failed: $e');
            debugPrintStack(stackTrace: st);
            error = e;
          }
        }

        if (error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    kDebugMode
                        ? 'Something went wrong.\n$error'
                        : 'Something went wrong. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: _retry, child: const Text('Retry')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loginService.signOut(),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }

        return destination ??
            const Scaffold(body: Center(child: Text('Unexpected state')));
      },
    );
  }
}
