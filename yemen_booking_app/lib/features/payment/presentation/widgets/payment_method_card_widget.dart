import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/payment_method_enum.dart';

class PaymentMethodCardWidget extends StatefulWidget {
  final PaymentMethod paymentMethod;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final String? lastFourDigits;
  final bool isSelected;

  const PaymentMethodCardWidget({
    super.key,
    required this.paymentMethod,
    required this.isSaved,
    required this.onTap,
    this.onDelete,
    this.lastFourDigits,
    this.isSelected = false,
  });

  @override
  State<PaymentMethodCardWidget> createState() => _PaymentMethodCardWidgetState();
}

class _PaymentMethodCardWidgetState extends State<PaymentMethodCardWidget>
    with SingleTickerProviderStateMixin {
  // Animation Controller
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
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
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? LinearGradient(
                        colors: [
                          _getMethodColor().withOpacity(0.2),
                          _getMethodColor().withOpacity(0.1),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          AppTheme.darkCard.withOpacity(0.6),
                          AppTheme.darkCard.withOpacity(0.3),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected
                      ? _getMethodColor()
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: [
                  if (widget.isSelected || _isPressed)
                    BoxShadow(
                      color: _getMethodColor().withOpacity(
                        0.3 * _glowAnimation.value,
                      ),
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
                    child: Row(
                      children: [
                        _buildIcon(),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDetails()),
                        if (widget.isSaved && widget.onDelete != null)
                          _buildDeleteButton(),
                        if (widget.isSelected) _buildSelectedIndicator(),
                      ],
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
  
  Widget _buildIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            _getMethodColor().withOpacity(0.3),
            _getMethodColor().withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getMethodColor().withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _getMethodIcon(),
          color: _getMethodColor(),
          size: 30,
        ),
      ),
    );
  }
  
  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.paymentMethod.displayNameAr,
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
            if (widget.isSaved) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.success.withOpacity(0.2),
                      AppTheme.success.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark,
                      size: 12,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'محفوظة',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 4),
        
        Text(
          _getMethodDescription(),
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        
        if (widget.lastFourDigits != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '•••• •••• •••• ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      LinearGradient(
                        colors: [
                          _getMethodColor(),
                          _getMethodColor().withOpacity(0.7),
                        ],
                      ).createShader(bounds),
                  child: Text(
                    widget.lastFourDigits!,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontFamily: 'monospace',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildDeleteButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.error.withOpacity(0.2),
            AppTheme.error.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onDelete?.call();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.delete_outline,
              color: AppTheme.error,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSelectedIndicator() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getMethodColor(),
            _getMethodColor().withOpacity(0.8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getMethodColor().withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 16,
      ),
    );
  }
  
  Color _getMethodColor() {
    switch (widget.paymentMethod) {
      case PaymentMethod.jwaliWallet:
        return const Color(0xFF00BCD4);
      case PaymentMethod.cashWallet:
        return const Color(0xFF4CAF50);
      case PaymentMethod.oneCashWallet:
        return const Color(0xFFFF9800);
      case PaymentMethod.floskWallet:
        return const Color(0xFF9C27B0);
      case PaymentMethod.jaibWallet:
        return const Color(0xFF3F51B5);
      case PaymentMethod.cash:
        return AppTheme.success;
      case PaymentMethod.paypal:
        return const Color(0xFF00457C);
      case PaymentMethod.creditCard:
        return AppTheme.primaryBlue;
    }
  }
  
  IconData _getMethodIcon() {
    switch (widget.paymentMethod) {
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
  
  String _getMethodDescription() {
    switch (widget.paymentMethod) {
      case PaymentMethod.jwaliWallet:
        return 'الدفع السريع عبر محفظة جوالي اليمنية';
      case PaymentMethod.cashWallet:
        return 'محفظة كاش الرقمية للمدفوعات الآمنة';
      case PaymentMethod.oneCashWallet:
        return 'حلول دفع متقدمة مع ون كاش';
      case PaymentMethod.floskWallet:
        return 'محفظة فلوس الإلكترونية السهلة';
      case PaymentMethod.jaibWallet:
        return 'محفظة جيب الذكية والمرنة';
      case PaymentMethod.cash:
        return 'الدفع نقداً عند الوصول';
      case PaymentMethod.paypal:
        return 'الدفع الآمن عبر PayPal';
      case PaymentMethod.creditCard:
        return 'Visa, Mastercard, American Express';
    }
  }
}