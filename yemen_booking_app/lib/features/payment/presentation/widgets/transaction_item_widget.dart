import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/payment_method_enum.dart';
import '../../domain/entities/transaction.dart';

class TransactionItemWidget extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionItemWidget({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  State<TransactionItemWidget> createState() => _TransactionItemWidgetState();
}

class _TransactionItemWidgetState extends State<TransactionItemWidget>
    with SingleTickerProviderStateMixin {
  // Animation Controller
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 0,
      end: 5,
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

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isRefund = widget.transaction.status == PaymentStatus.refunded ||
        widget.transaction.status == PaymentStatus.partiallyRefunded;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(_slideAnimation.value, 0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.darkCard.withOpacity(0.6),
                      AppTheme.darkCard.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor().withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    if (_isPressed)
                      BoxShadow(
                        color: _getStatusColor().withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    BoxShadow(
                      color: AppTheme.shadowDark.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildHeader(isRefund),
                          const SizedBox(height: 16),
                          _buildDetails(),
                          const SizedBox(height: 16),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildHeader(bool isRefund) {
    return Row(
      children: [
        _buildStatusIcon(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.transaction.propertyName,
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.meeting_room,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.transaction.unitName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildAmount(isRefund),
      ],
    );
  }
  
  Widget _buildStatusIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            _getStatusColor().withOpacity(0.3),
            _getStatusColor().withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _getStatusIcon(),
          color: _getStatusColor(),
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildAmount(bool isRefund) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            if (isRefund)
              Text(
                '-',
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.error,
                ),
              ),
            ShaderMask(
              shaderCallback: (bounds) =>
                  LinearGradient(
                    colors: isRefund
                        ? [AppTheme.error, AppTheme.error.withOpacity(0.8)]
                        : [_getStatusColor(), _getStatusColor().withOpacity(0.8)],
                  ).createShader(bounds),
              child: Text(
                widget.transaction.amount.toStringAsFixed(0),
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.transaction.currency,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        if (widget.transaction.fees > 0)
          Text(
            '+ ${widget.transaction.fees.toStringAsFixed(0)} رسوم',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withOpacity(0.7),
            ),
          ),
      ],
    );
  }
  
  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkBackground.withOpacity(0.5),
            AppTheme.darkBackground.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDetailItem(
            icon: Icons.confirmation_number,
            label: 'رقم الحجز',
            value: widget.transaction.bookingNumber,
          ),
          Container(
            width: 1,
            height: 35,
            color: AppTheme.darkBorder.withOpacity(0.3),
          ),
          _buildDetailItem(
            icon: _getPaymentMethodIcon(),
            label: 'طريقة الدفع',
            value: widget.transaction.paymentMethod.displayNameAr,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryBlue.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor().withOpacity(0.2),
                    _getStatusColor().withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor().withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.transaction.status.displayNameAr,
                    style: AppTextStyles.caption.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Refundable Badge
            if (widget.transaction.canRefund) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warning.withOpacity(0.2),
                      AppTheme.warning.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.replay,
                      size: 12,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'قابل للاسترداد',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        
        // Date and Time
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 12,
              color: AppTheme.textMuted.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(widget.transaction.createdAt),
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Color _getStatusColor() {
    switch (widget.transaction.status) {
      case PaymentStatus.successful:
        return AppTheme.success;
      case PaymentStatus.failed:
        return AppTheme.error;
      case PaymentStatus.pending:
        return AppTheme.warning;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return AppTheme.info;
      case PaymentStatus.voided:
        return AppTheme.textMuted;
    }
  }
  
  IconData _getStatusIcon() {
    switch (widget.transaction.status) {
      case PaymentStatus.successful:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.cancel;
      case PaymentStatus.pending:
        return Icons.hourglass_empty;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Icons.replay;
      case PaymentStatus.voided:
        return Icons.block;
    }
  }
  
  IconData _getPaymentMethodIcon() {
    switch (widget.transaction.paymentMethod) {
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.paypal:
        return Icons.payment;
      default:
        return Icons.account_balance_wallet;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'اليوم ${DateFormat('HH:mm').format(date)}';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'أمس ${DateFormat('HH:mm').format(date)}';
    } else if (date.year == now.year) {
      return DateFormat('dd MMM - HH:mm', 'ar').format(date);
    } else {
      return DateFormat('dd/MM/yyyy', 'ar').format(date);
    }
  }
}