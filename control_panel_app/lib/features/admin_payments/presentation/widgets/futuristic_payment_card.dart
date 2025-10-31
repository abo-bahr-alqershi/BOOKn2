import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../domain/entities/payment.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/app_dimensions.dart';
import '../../../../../../core/widgets/price_widget.dart';
import '../../../../../../core/widgets/payment_identity_card_tooltip.dart'; // 🎯 إضافة
import 'payment_status_indicator.dart';
import 'payment_method_icon.dart';

class FuturisticPaymentCard extends StatefulWidget {
  final Payment payment;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool showActions;
  final VoidCallback? onRefundTap;
  final VoidCallback? onVoidTap;

  const FuturisticPaymentCard({
    super.key,
    required this.payment,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.showActions = false,
    this.onRefundTap,
    this.onVoidTap,
  });

  @override
  State<FuturisticPaymentCard> createState() => _FuturisticPaymentCardState();
}

class _FuturisticPaymentCardState extends State<FuturisticPaymentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;
  final GlobalKey _cardKey = GlobalKey(); // 🎯 GlobalKey للـ tooltip

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showTooltip() {
    PaymentIdentityCardTooltip.show(
      context: context,
      targetKey: _cardKey,
      paymentId: widget.payment.id,
      transactionId: widget.payment.transactionId,
      amount: widget.payment.amount.amount,
      currency: widget.payment.amount.currency,
      paymentMethod: _getMethodName(widget.payment.method),
      status: _getStatusName(widget.payment.status),
      paymentDate: widget.payment.paymentDate,
      userName: widget.payment.userName,
      userEmail: widget.payment.userEmail,
      bookingId: widget.payment.bookingId,
      propertyName: widget.payment.propertyName,
      unitName: widget.payment.unitName,
      refundedAmount: widget.payment.refundedAmount,
      refundedAt: widget.payment.refundedAt,
      refundReason: widget.payment.refundReason,
      refundTransactionId: widget.payment.refundTransactionId,
      isVoided: widget.payment.isVoided,
      voidedAt: widget.payment.voidedAt,
      voidReason: widget.payment.voidReason,
    );
  }

  String _getMethodName(dynamic method) {
    return method.toString().split('.').last;
  }

  String _getStatusName(dynamic status) {
    return status.toString().split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            key: _cardKey, // 🎯 إضافة key
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? AppTheme.primaryBlue
                          .withValues(alpha: 0.3 * _glowAnimation.value)
                      : AppTheme.shadowDark.withValues(alpha: 0.1),
                  blurRadius: widget.isSelected ? 20 : 10,
                  offset: const Offset(0, 4),
                  spreadRadius: widget.isSelected ? 2 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: GestureDetector(
                  onTapDown: (_) => _handleTapDown(),
                  onTapUp: (_) => _handleTapUp(),
                  onTapCancel: () => _handleTapCancel(),
                  onTap: widget.onTap,
                  onLongPress: () { // 🎯 عرض tooltip عند النقر المطول
                    _showTooltip();
                    if (widget.onLongPress != null) {
                      widget.onLongPress!();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12), // 🎯 تقليل padding
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isSelected
                            ? [
                                AppTheme.primaryBlue.withValues(alpha: 0.2),
                                AppTheme.primaryPurple.withValues(alpha: 0.1),
                              ]
                            : [
                                AppTheme.darkCard.withValues(alpha: 0.8),
                                AppTheme.darkCard.withValues(alpha: 0.6),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.isSelected
                            ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                            : AppTheme.darkBorder.withValues(alpha: 0.3),
                        width: widget.isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 🎯 إصلاح overflow
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 8), // 🎯 تقليل المسافة
                        _buildContent(),
                        if (widget.showActions) ...[
                          const SizedBox(height: 8), // 🎯 تقليل المسافة
                          _buildActions(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Payment Method Icon
        PaymentMethodIcon(
          method: widget.payment.method,
          size: 32,
        ),
        const SizedBox(width: 12),

        // Payment Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 🎯 Flexible للنص الطويل
                  Flexible(
                    child: Text(
                      '#${widget.payment.transactionId}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PaymentStatusIndicator(
                    status: widget.payment.status,
                    size: PaymentStatusSize.small,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(widget.payment.paymentDate),
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),

        // Amount
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            PriceWidget(
              price: widget.payment.amount.amount,
              currency: widget.payment.amount.currency,
              displayType: PriceDisplayType.compact,
              priceStyle: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.payment.refundedAmount != null &&
                widget.payment.refundedAmount! > 0)
              Text(
                'مسترد: ${widget.payment.refundedAmount} ${widget.payment.amount.currency}',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.warning,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(8), // 🎯 تقليل padding
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🎯 إصلاح overflow
        children: [
          _buildInfoRow(
            icon: CupertinoIcons.person_fill,
            label: 'العميل',
            value: widget.payment.userName ?? 'غير محدد',
          ),
          const SizedBox(height: 6), // 🎯 تقليل المسافة
          _buildInfoRow(
            icon: CupertinoIcons.bed_double_fill,
            label: 'الحجز',
            value: widget.payment.bookingId,
          ),
          if (widget.payment.propertyName != null) ...[
            const SizedBox(height: 6), // 🎯 تقليل المسافة
            _buildInfoRow(
              icon: CupertinoIcons.building_2_fill,
              label: 'العقار',
              value: widget.payment.propertyName!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.textMuted,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textWhite,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (widget.payment.canRefund && widget.onRefundTap != null)
          Expanded(
            child: _buildActionButton(
              icon: CupertinoIcons.arrow_counterclockwise,
              label: 'استرداد',
              color: AppTheme.warning,
              onTap: widget.onRefundTap!,
            ),
          ),
        if (widget.payment.canVoid && widget.onVoidTap != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              icon: CupertinoIcons.xmark_circle,
              label: 'إلغاء',
              color: AppTheme.error,
              onTap: widget.onVoidTap!,
            ),
          ),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: CupertinoIcons.doc_on_doc,
            label: 'نسخ',
            color: AppTheme.primaryBlue,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTapDown() {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _handleTapUp() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
