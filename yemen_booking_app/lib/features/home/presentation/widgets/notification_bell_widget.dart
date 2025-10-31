// lib/features/home/presentation/widgets/common/notification_bell_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationBellWidget extends StatelessWidget {
  final VoidCallback onTap;
  final int unreadCount;

  const NotificationBellWidget({
    super.key,
    required this.onTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              size: 18,
              color: Colors.white,
            ),
            onPressed: onTap,
            padding: EdgeInsets.zero,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error,
                    AppTheme.error,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.darkCard,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.error.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
