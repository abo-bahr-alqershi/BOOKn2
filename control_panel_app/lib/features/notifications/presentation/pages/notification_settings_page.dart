// lib/features/notifications/presentation/pages/notification_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  Map<String, bool> _settings = {};

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    context.read<NotificationBloc>().add(
          const LoadNotificationSettingsEvent(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildAppBar(),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationSettingsLoaded) {
            setState(() {
              _settings = state.settings;
            });
          } else if (state is NotificationError) {
            _showErrorSnackbar(state.message);
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل الإعدادات...',
            );
          }

          return _buildContent();
        },
      ),
      // Save button removed; updates happen instantly on toggle change
      bottomNavigationBar: null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.darkBackground,
      elevation: 0,
      title: Text(
        'إعدادات الإشعارات',
        style: AppTextStyles.heading2.copyWith(
          color: AppTheme.textWhite,
        ),
      ),
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(
          CupertinoIcons.arrow_right,
          color: AppTheme.textWhite,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'قنوات الإشعارات',
            icon: CupertinoIcons.bell_circle_fill,
            children: [
              _buildSettingTile(
                key: 'push_notifications',
                title: 'الإشعارات الفورية',
                subtitle: 'تلقي إشعارات فورية على جهازك',
                icon: CupertinoIcons.device_phone_portrait,
              ),
              _buildSettingTile(
                key: 'email_notifications',
                title: 'البريد الإلكتروني',
                subtitle: 'تلقي إشعارات عبر البريد الإلكتروني',
                icon: CupertinoIcons.mail,
              ),
              _buildSettingTile(
                key: 'sms_notifications',
                title: 'الرسائل النصية',
                subtitle: 'تلقي إشعارات عبر رسائل SMS',
                icon: CupertinoIcons.bubble_left,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'إشعارات الحجوزات',
            icon: CupertinoIcons.calendar,
            children: [
              _buildSettingTile(
                key: 'booking_confirmed',
                title: 'تأكيد الحجز',
                subtitle: 'إشعار عند تأكيد حجز جديد',
                icon: CupertinoIcons.checkmark_circle,
              ),
              _buildSettingTile(
                key: 'booking_cancelled',
                title: 'إلغاء الحجز',
                subtitle: 'إشعار عند إلغاء حجز',
                icon: CupertinoIcons.xmark_circle,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'إشعارات المدفوعات',
            icon: CupertinoIcons.creditcard,
            children: [
              _buildSettingTile(
                key: 'payment_received',
                title: 'استلام دفعة',
                subtitle: 'إشعار عند استلام دفعة جديدة',
                icon: CupertinoIcons.money_dollar_circle,
              ),
              _buildSettingTile(
                key: 'payment_refunded',
                title: 'استرداد دفعة',
                subtitle: 'إشعار عند استرداد دفعة',
                icon: CupertinoIcons.arrow_counterclockwise_circle,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'إشعارات أخرى',
            icon: CupertinoIcons.square_grid_2x2,
            children: [
              _buildSettingTile(
                key: 'promotion_new',
                title: 'العروض والخصومات',
                subtitle: 'إشعار بالعروض والخصومات الجديدة',
                icon: CupertinoIcons.gift,
              ),
              _buildSettingTile(
                key: 'system_updates',
                title: 'تحديثات النظام',
                subtitle: 'إشعار بتحديثات وصيانة النظام',
                icon: CupertinoIcons.gear,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.05),
                      AppTheme.primaryPurple.withValues(alpha: 0.03),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.darkBorder.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _settings[key] ?? false,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                _settings[key] = value;
                _hasChanges = false; // no pending changes; saved instantly
              });
              // Update instantly (no save button)
              context.read<NotificationBloc>().add(
                    UpdateNotificationSettingsEvent(settings: _settings),
                  );
            },
            activeTrackColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppTheme.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
