import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../domain/entities/payment.dart';
import '../../domain/entities/refund.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/app_dimensions.dart';
import '../../../../../../core/widgets/price_widget.dart';

class RefundDialog extends StatefulWidget {
  final Payment payment;
  final Function(Money amount, String reason) onRefund;

  const RefundDialog({
    super.key,
    required this.payment,
    required this.onRefund,
  });

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  RefundType _refundType = RefundType.full;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;

  final List<String> _commonReasons = [
    'طلب العميل',
    'خطأ في الدفع',
    'إلغاء الحجز',
    'خدمة غير مرضية',
    'خطأ فني',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // خلفية رخامية متحركة
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.darkBackground,
                        AppTheme.darkBackground2,
                        AppTheme.darkBackground3.withOpacity(0.5),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Animated Orbs
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Stack(
                            children: [
                              // Top Orb
                              Positioned(
                                top: -30 + (15 * _pulseController.value),
                                right: -30,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppTheme.warning.withOpacity(0.2),
                                        AppTheme.warning.withOpacity(0.05),
                                        AppTheme.warning.withOpacity(0.01),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Bottom Orb
                              Positioned(
                                bottom: -50 + (10 * _pulseController.value),
                                left: -40,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppTheme.error.withOpacity(0.15),
                                        AppTheme.error.withOpacity(0.04),
                                        AppTheme.error.withOpacity(0.01),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // المحتوى مع شفافية
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.darkCard.withOpacity(0.7),
                        AppTheme.darkCard.withOpacity(0.5),
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.glowBlue.withOpacity(0.1),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warning.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            Flexible(
                              child: SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom +
                                          20,
                                ),
                                child: _buildContent(),
                              ),
                            ),
                            _buildActions(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warning.withOpacity(0.1),
            AppTheme.error.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon with Glow Effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warning,
                      AppTheme.error,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warning.withOpacity(
                        0.3 + (0.2 * _pulseController.value),
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.arrow_counterclockwise_circle_fill,
                  color: Colors.white,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'استرداد المبلغ',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'معاملة #${widget.payment.transactionId}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textWhite.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppTheme.textWhite,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorder,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المبلغ الأصلي',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    PriceWidget(
                      price: widget.payment.amount.amount,
                      currency: widget.payment.amount.currency,
                      displayType: PriceDisplayType.normal,
                    ),
                  ],
                ),
                if (widget.payment.refundedAmount != null &&
                    widget.payment.refundedAmount! > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المبلغ المسترد',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        '${widget.payment.refundedAmount} ${widget.payment.amount.currency}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Divider(color: AppTheme.darkBorder),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المتاح للاسترداد',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.payment.remainingRefundableAmount} ${widget.payment.amount.currency}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Refund Type
          Text(
            'نوع الاسترداد',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRefundTypeOption(
                  RefundType.full,
                  'استرداد كامل',
                  CupertinoIcons.arrow_counterclockwise_circle_fill,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRefundTypeOption(
                  RefundType.partial,
                  'استرداد جزئي',
                  CupertinoIcons.arrow_counterclockwise_circle,
                ),
              ),
            ],
          ),

          // Amount Input (for partial refund)
          if (_refundType == RefundType.partial) ...[
            const SizedBox(height: 20),
            Text(
              'المبلغ المراد استرداده',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.darkBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppTheme.textWhite,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.money_dollar,
                      color: AppTheme.textMuted,
                    ),
                    suffixText: widget.payment.amount.currency,
                    suffixStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Reason Selection
          Text(
            'سبب الاسترداد',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonReasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedReason = reason;
                    if (reason != 'أخرى') {
                      _reasonController.text = reason;
                    } else {
                      _reasonController.clear();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                        : AppTheme.darkBackground.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.darkBorder,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    reason,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.textLight,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Custom Reason Input
          if (_selectedReason == 'أخرى') ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.darkBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                  ),
                  decoration: InputDecoration(
                    hintText: 'اكتب السبب هنا...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefundTypeOption(
    RefundType type,
    String label,
    IconData icon,
  ) {
    final isSelected = _refundType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _refundType = type;
          if (type == RefundType.full) {
            _amountController.text =
                widget.payment.remainingRefundableAmount.toStringAsFixed(2);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected
              ? null
              : AppTheme.darkBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.darkBorder,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.textWhite,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppTheme.textLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkBackground.withOpacity(0.3),
            AppTheme.darkCard.withOpacity(0.2),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.darkBorder.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'إلغاء',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _processRefund,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warning,
                        AppTheme.error,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warning.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'تأكيد الاسترداد',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processRefund() {
    if (_reasonController.text.isEmpty && _selectedReason != 'أخرى') {
      _reasonController.text = _selectedReason ?? '';
    }

    if (_reasonController.text.isEmpty) {
      // Show error
      return;
    }

    double amount;
    if (_refundType == RefundType.full) {
      amount = widget.payment.remainingRefundableAmount;
    } else {
      amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0 || amount > widget.payment.remainingRefundableAmount) {
        // Show error
        return;
      }
    }

    final refundAmount = Money(
      amount: amount,
      currency: widget.payment.amount.currency,
      formattedAmount: '$amount ${widget.payment.amount.currency}',
    );

    widget.onRefund(refundAmount, _reasonController.text);
  }
}
