import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/enums/payment_method_enum.dart';

enum PaymentStatusSize { small, medium, large }

class PaymentStatusIndicator extends StatefulWidget {
  final PaymentStatus status;
  final PaymentStatusSize size;
  final bool showAnimation;
  final bool showIcon;

  const PaymentStatusIndicator({
    super.key,
    required this.status,
    this.size = PaymentStatusSize.medium,
    this.showAnimation = true,
    this.showIcon = true,
  });

  @override
  State<PaymentStatusIndicator> createState() => _PaymentStatusIndicatorState();
}

class _PaymentStatusIndicatorState extends State<PaymentStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.showAnimation && _shouldAnimate()) {
      _animationController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      )..repeat(reverse: true);

      _pulseAnimation = Tween<double>(
        begin: 0.9,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
    } else {
      _animationController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      );
      _pulseAnimation = const AlwaysStoppedAnimation(1.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _shouldAnimate() {
    return widget.status == PaymentStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: _getPadding(),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor().withValues(alpha: 0.2),
                  _getStatusColor().withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(_getBorderRadius()),
              border: Border.all(
                color: _getStatusColor().withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showIcon) ...[
                  _buildIcon(),
                  SizedBox(width: _getSpacing()),
                ],
                Text(
                  _getStatusText(),
                  style: _getTextStyle(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    IconData icon;
    switch (widget.status) {
      case PaymentStatus.successful:
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case PaymentStatus.pending:
        icon = CupertinoIcons.clock_fill;
        break;
      case PaymentStatus.failed:
        icon = CupertinoIcons.xmark_circle_fill;
        break;
      case PaymentStatus.refunded:
        icon = CupertinoIcons.arrow_counterclockwise_circle_fill;
        break;
      case PaymentStatus.partiallyRefunded:
        icon = CupertinoIcons.arrow_counterclockwise_circle;
        break;
      default:
        icon = CupertinoIcons.info_circle_fill;
        break;
    }

    return Icon(
      icon,
      color: _getStatusColor(),
      size: _getIconSize(),
    );
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case PaymentStatus.successful:
        return AppTheme.success;
      case PaymentStatus.pending:
        return AppTheme.warning;
      case PaymentStatus.failed:
        return AppTheme.error;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return AppTheme.info;
      default:
        return AppTheme.info;
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case PaymentStatus.successful:
        return 'مكتمل';
      case PaymentStatus.pending:
        return 'معلق';
      case PaymentStatus.failed:
        return 'فاشل';
      case PaymentStatus.refunded:
        return 'مسترد';
      case PaymentStatus.partiallyRefunded:
        return 'مسترد جزئياً';
      default:
        return 'غير معروف';
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case PaymentStatusSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case PaymentStatusSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case PaymentStatusSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case PaymentStatusSize.small:
        return 12;
      case PaymentStatusSize.medium:
        return 16;
      case PaymentStatusSize.large:
        return 20;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case PaymentStatusSize.small:
        return 12;
      case PaymentStatusSize.medium:
        return 16;
      case PaymentStatusSize.large:
        return 20;
    }
  }

  double _getSpacing() {
    switch (widget.size) {
      case PaymentStatusSize.small:
        return 4;
      case PaymentStatusSize.medium:
        return 6;
      case PaymentStatusSize.large:
        return 8;
    }
  }

  TextStyle _getTextStyle() {
    TextStyle baseStyle;
    switch (widget.size) {
      case PaymentStatusSize.small:
        baseStyle = AppTextStyles.caption;
        break;
      case PaymentStatusSize.medium:
        baseStyle = AppTextStyles.bodySmall;
        break;
      case PaymentStatusSize.large:
        baseStyle = AppTextStyles.bodyMedium;
        break;
    }

    return baseStyle.copyWith(
      color: _getStatusColor(),
      fontWeight: FontWeight.bold,
    );
  }
}
