import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/price_widget.dart';

class PriceBreakdownWidget extends StatefulWidget {
  final int nights;
  final double pricePerNight;
  final double servicesTotal;
  final double taxRate;
  final String currency;
  final double? discount;
  final String? promoCode;

  const PriceBreakdownWidget({
    super.key,
    required this.nights,
    required this.pricePerNight,
    required this.servicesTotal,
    required this.taxRate,
    required this.currency,
    this.discount,
    this.promoCode,
  });

  @override
  State<PriceBreakdownWidget> createState() => _PriceBreakdownWidgetState();
}

class _PriceBreakdownWidgetState extends State<PriceBreakdownWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _shimmerController;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    // Create item animations
    _itemControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: Duration(milliseconds: 200 + (index * 50)),
        vsync: this,
      ),
    );
    
    _itemAnimations = _itemControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
    }).toList();
  }

  @override
  void dispose() {
    _expandController.dispose();
    _shimmerController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
        for (var controller in _itemControllers) {
          controller.forward();
        }
      } else {
        _expandController.reverse();
        for (var controller in _itemControllers.reversed) {
          controller.reverse();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accommodationTotal = widget.nights * widget.pricePerNight;
    final subtotal = accommodationTotal + widget.servicesTotal;
    final discountAmount = widget.discount ?? 0;
    final afterDiscount = subtotal - discountAmount;
    final taxAmount = afterDiscount * widget.taxRate;
    final total = afterDiscount + taxAmount;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              // Subtle shimmer background
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1 + _shimmerController.value * 0.5, 0),
                          end: Alignment(-0.5 + _shimmerController.value * 0.5, 0),
                          colors: [
                            Colors.transparent,
                            AppTheme.primaryBlue.withOpacity(0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactHeader(),
                    const SizedBox(height: 12),
                    
                    // Summary (always visible)
                    _buildCompactSummaryRow(total),
                    
                    // Expandable details
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: _isExpanded ? _buildCompactDetails(
                        accommodationTotal: accommodationTotal,
                        subtotal: subtotal,
                        discountAmount: discountAmount,
                        taxAmount: taxAmount,
                        total: total,
                      ) : const SizedBox.shrink(),
                    ),
                    
                    const SizedBox(height: 8),
                    _buildCompactToggleButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.2),
                AppTheme.primaryPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            color: AppTheme.primaryBlue.withOpacity(0.9),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'تفاصيل السعر',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSummaryRow(double total) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'المجموع الكلي',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textWhite.withOpacity(0.9),
            ),
          ),
          PriceWidget(
            price: total,
            currency: widget.currency,
            displayType: PriceDisplayType.compact,
            priceStyle: AppTextStyles.bodyLarge.copyWith(
              color: AppTheme.primaryBlue.withOpacity(0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetails({
    required double accommodationTotal,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double total,
  }) {
    return Column(
      children: [
        const SizedBox(height: 12),
        
        // Accommodation
        _buildAnimatedCompactPriceRow(
          label: 'الإقامة (${widget.nights} × ${widget.pricePerNight.toStringAsFixed(0)} ${widget.currency})',
          amount: accommodationTotal,
          index: 0,
          icon: Icons.hotel_rounded,
          color: AppTheme.primaryBlue.withOpacity(0.8),
        ),
        
        // Services
        if (widget.servicesTotal > 0) ...[
          const SizedBox(height: 8),
          _buildAnimatedCompactPriceRow(
            label: 'الخدمات الإضافية',
            amount: widget.servicesTotal,
            index: 1,
            icon: Icons.room_service_rounded,
            color: AppTheme.primaryPurple.withOpacity(0.8),
          ),
        ],
        
        // Subtotal
        const SizedBox(height: 10),
        _buildSubtleDivider(),
        const SizedBox(height: 10),
        _buildAnimatedCompactPriceRow(
          label: 'المجموع الفرعي',
          amount: subtotal,
          index: 2,
          isSubtotal: true,
        ),
        
        // Discount
        if (discountAmount > 0) ...[
          const SizedBox(height: 8),
          _buildAnimatedCompactPriceRow(
            label: 'الخصم${widget.promoCode != null ? ' (${widget.promoCode})' : ''}',
            amount: -discountAmount,
            index: 3,
            icon: Icons.discount_rounded,
            color: AppTheme.success.withOpacity(0.8),
            isDiscount: true,
          ),
        ],
        
        // Tax
        const SizedBox(height: 8),
        _buildAnimatedCompactPriceRow(
          label: 'الضرائب (${(widget.taxRate * 100).toStringAsFixed(0)}%)',
          amount: taxAmount,
          index: 4,
          icon: Icons.account_balance_rounded,
          color: AppTheme.warning.withOpacity(0.8),
        ),
      ],
    );
  }

  Widget _buildAnimatedCompactPriceRow({
    required String label,
    required double amount,
    required int index,
    IconData? icon,
    Color? color,
    bool isSubtotal = false,
    bool isDiscount = false,
  }) {
    return AnimatedBuilder(
      animation: _itemAnimations[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset((1 - _itemAnimations[index].value) * 20, 0),
          child: Opacity(
            opacity: _itemAnimations[index].value,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: isSubtotal
                  ? BoxDecoration(
                      color: AppTheme.darkCard.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color!.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        icon,
                        size: 12,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: isSubtotal 
                            ? AppTheme.textWhite.withOpacity(0.9)
                            : (isDiscount 
                                ? AppTheme.success.withOpacity(0.8) 
                                : AppTheme.textMuted.withOpacity(0.7)),
                        fontWeight: isSubtotal ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    '${isDiscount ? '' : ''}${amount.toStringAsFixed(0)} ${widget.currency}',
                    style: AppTextStyles.caption.copyWith(
                      color: isDiscount 
                          ? AppTheme.success.withOpacity(0.8)
                          : (isSubtotal 
                              ? AppTheme.textWhite.withOpacity(0.9) 
                              : AppTheme.textWhite.withOpacity(0.8)),
                      fontWeight: isSubtotal ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtleDivider() {
    return Container(
      height: 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.darkBorder.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildCompactToggleButton() {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded ? 'إخفاء التفاصيل' : 'عرض التفاصيل',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.primaryBlue.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more_rounded,
                color: AppTheme.primaryBlue.withOpacity(0.9),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}