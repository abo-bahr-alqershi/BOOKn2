// lib/features/home/presentation/widgets/sections/section_error_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class SectionErrorWidget extends StatefulWidget {
  final String? message;
  final VoidCallback? onRetry;

  const SectionErrorWidget({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  State<SectionErrorWidget> createState() => _SectionErrorWidgetState();
}

class _SectionErrorWidgetState extends State<SectionErrorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error
                        .withValues(alpha: 0.1 * _pulseAnimation.value),
                    AppTheme.error
                        .withValues(alpha: 0.05 * _pulseAnimation.value),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.error.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.message ?? 'حدث خطأ في تحميل البيانات',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.onRetry != null) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: widget.onRetry,
                      child: Text(
                        'إعادة المحاولة',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
