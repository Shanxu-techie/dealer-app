import 'package:dealer_app/shared/models/app_user_role.dart';
import 'package:flutter/material.dart';

class AppSharedBar extends StatelessWidget implements PreferredSizeWidget {
  const AppSharedBar({
    super.key,
    required this.title,
    required this.role,
    this.hasUnseenNotification = false,
    this.onNotificationsTap,
    this.onProfileTap,
    required this.onLogoutTap,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final AppUserRole role;
  final bool hasUnseenNotification;
  final bool automaticallyImplyLeading;

  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final VoidCallback onLogoutTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Text(title),
      actions: [
        if (role == AppUserRole.dealer)
          PopupMenuButton<String>(
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: hasUnseenNotification,
              smallSize: 8,
              child: const Icon(Icons.notifications_outlined),
            ),
            onSelected: (value) {
              if (value == 'price_letter') {
                onNotificationsTap?.call();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'price_letter',
                child: Text('New price update available'),
              ),
            ],
          ),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          icon: const Icon(Icons.account_circle_outlined),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                onProfileTap?.call();
                break;
              case 'logout':
                onLogoutTap();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'profile', child: Text('Profile')),
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
      ],
    );
  }
}
