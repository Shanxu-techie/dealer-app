import 'package:dealer_app/login/login_service.dart';
import 'package:dealer_app/shared/models/app_user_role.dart';
import 'package:dealer_app/shared/widgets/app_shared_bar.dart';
import 'package:flutter/material.dart';

class PriceLetterErrorPage extends StatelessWidget {
  const PriceLetterErrorPage({
    super.key,
    required this.message,
    required this.role,
  });

  final String message;
  final AppUserRole role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppSharedBar(
        title: 'Price Letter',
        role: role,
        hasUnseenNotification: false,
        onNotificationsTap: null,
        onProfileTap: null,
        onLogoutTap: () async {
          await LoginService().signOutAndReturnToLogin(context);
        },
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Price Letter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
