import 'package:dealer_app/shared/models/app_user_role.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppSharedBar extends StatelessWidget implements PreferredSizeWidget {
  const AppSharedBar({
    super.key,
    required this.title,
    required this.role,
    this.hasUnseenNotification = false,
    this.onNotificationsTap,
    required this.onLogoutTap,
    this.automaticallyImplyLeading = true,
    this.notificationMsPrice,
    this.notificationHsdPrice,
    this.notificationEffectiveDate,
  });

  final String title;
  final AppUserRole role;
  final bool hasUnseenNotification;
  final bool automaticallyImplyLeading;

  final VoidCallback? onNotificationsTap;
  final VoidCallback onLogoutTap;

  final double? notificationMsPrice;
  final double? notificationHsdPrice;
  final DateTime? notificationEffectiveDate;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
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
            itemBuilder: (context) {
              if (!hasUnseenNotification) {
                return const [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: ListTile(
                      leading: Icon(Icons.notifications_none),
                      title: Text('No new notifications'),
                    ),
                  ),
                ];
              }

              return [
                PopupMenuItem<String>(
                  value: 'price_letter',
                  child: ListTile(
                    leading: const Icon(Icons.local_gas_station_outlined),
                    title: const Text('New fuel price update'),
                    subtitle: Text(
                      [
                        if (notificationMsPrice != null)
                          'MS: ${notificationMsPrice!.toStringAsFixed(2)}',
                        if (notificationHsdPrice != null)
                          'HSD: ${notificationHsdPrice!.toStringAsFixed(2)}',
                        if (notificationEffectiveDate != null)
                          'Effective ${DateFormat('dd MMM yyyy').format(notificationEffectiveDate!)}',
                      ].join('\n'),
                    ),
                  ),
                ),
              ];
            },
          ),

        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout),
          onPressed: onLogoutTap,
        ),
      ],
    );
  }
}
