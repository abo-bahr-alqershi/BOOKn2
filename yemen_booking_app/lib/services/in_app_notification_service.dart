import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:yemen_booking_app/services/navigation_service.dart';
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';

class InAppNotificationService {
  InAppNotificationService._();

  static bool _isShowing = false;

  static Future<void> showNotificationDialog({
    required String title,
    required String body,
    required VoidCallback? onOpen,
    Color? accent,
    String? priority,
  }) async {
    if (_isShowing) return;
    for (int i = 0; i < 8; i++) {
      final context = NavigationService.rootNavigatorKey.currentContext;
      if (context != null) {
        _isShowing = true;
        try {
          await showGeneralDialog(
            context: context,
            useRootNavigator: true,
            barrierDismissible: true,
            barrierLabel: 'notification',
            barrierColor: Colors.black87,
            transitionDuration: const Duration(milliseconds: 250),
            pageBuilder: (context, anim1, anim2) {
              final color = accent ?? _resolveAccent(priority);
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.1),
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          style: AppTextStyles.heading3.copyWith(
                            color: AppTheme.textWhite,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          body,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context, rootNavigator: true).pop();
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'إغلاق',
                                  style: AppTextStyles.buttonMedium.copyWith(
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.of(context, rootNavigator: true).pop();
                                  if (onOpen != null) onOpen();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'فتح',
                                  style: AppTextStyles.buttonMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            transitionBuilder: (context, anim, secondaryAnim, child) {
              final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(curved),
                  child: child,
                ),
              );
            },
          );
        } finally {
          _isShowing = false;
        }
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  static Color _resolveAccent(String? priority) {
    final p = (priority ?? '').toLowerCase().trim();
    switch (p) {
      case 'high':
      case 'critical':
      case 'urgent':
      case 'danger':
      case 'error':
        return AppTheme.error;
      case 'medium':
      case 'warn':
      case 'warning':
        return AppTheme.warning;
      case 'success':
      case 'ok':
      case 'done':
        return AppTheme.success;
      case 'low':
      case 'normal':
      case 'default':
      case 'info':
      default:
        return AppTheme.info;
    }
  }
}
