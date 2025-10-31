import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

class CustomErrorWidget extends StatelessWidget {
  final String? message;
  final String? title;
  final VoidCallback? onRetry;
  final Widget? icon;
  final ErrorType type;

  const CustomErrorWidget({
    super.key,
    this.message,
    this.title,
    this.onRetry,
    this.icon,
    this.type = ErrorType.general,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(context),
            const SizedBox(height: AppDimensions.spaceLarge),
            _buildTitle(context),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.spaceSmall),
              _buildMessage(context),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spaceXLarge),
              _buildRetryButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    if (icon != null) return icon!;

    IconData iconData;
    Color iconColor;

    switch (type) {
      case ErrorType.network:
        iconData = Icons.wifi_off_rounded;
        iconColor = AppTheme.error;
        break;
      case ErrorType.server:
        iconData = Icons.cloud_off_rounded;
        iconColor = AppTheme.error;
        break;
      case ErrorType.notFound:
        iconData = Icons.search_off_rounded;
        iconColor = AppTheme.textMuted;
        break;
      case ErrorType.permission:
        iconData = Icons.lock_outline_rounded;
        iconColor = AppTheme.warning;
        break;
      case ErrorType.general:
        iconData = Icons.error_outline_rounded;
        iconColor = AppTheme.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: AppDimensions.iconXLarge,
        color: iconColor,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    String displayTitle = title ?? _getDefaultTitle();
    
    return Text(
      displayTitle,
      style: AppTextStyles.heading3.copyWith(
        color: AppTheme.textWhite,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Text(
      message!,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppTheme.textMuted,
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return           Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.error.withValues(alpha: 0.7),
                  AppTheme.error.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'إعادة المحاولة',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  String _getDefaultTitle() {
    switch (type) {
      case ErrorType.network:
        return 'لا يوجد اتصال بالإنترنت';
      case ErrorType.server:
        return 'خطأ في الخادم';
      case ErrorType.notFound:
        return 'لم يتم العثور على النتائج';
      case ErrorType.permission:
        return 'ليس لديك صلاحية';
      case ErrorType.general:
        return 'حدث خطأ ما';
    }
  }
}

enum ErrorType {
  general,
  network,
  server,
  notFound,
  permission,
}