// lib/features/admin_units/presentation/widgets/unit_pricing_cards.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/money.dart';
import '../../domain/entities/pricing_method.dart';

class UnitPricingCards extends StatefulWidget {
  final Money basePrice;
  final PricingMethod pricingMethod;
  final double discountPercentage;
  final List<SeasonalPrice> seasonalPrices;

  const UnitPricingCards({
    super.key,
    required this.basePrice,
    required this.pricingMethod,
    required this.discountPercentage,
    this.seasonalPrices = const [],
  });

  @override
  State<UnitPricingCards> createState() => _UnitPricingCardsState();
}

class _UnitPricingCardsState extends State<UnitPricingCards>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _pulseAnimationController;
  int _selectedPriceIndex = 0;

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            // Base Price Card
            _buildMainPriceCard(),

            const SizedBox(height: 20),

            // Pricing Options
            _buildPricingOptions(),

            const SizedBox(height: 20),

            // Seasonal Prices
            if (widget.seasonalPrices.isNotEmpty) ...[
              _buildSectionTitle('الأسعار الموسمية', CupertinoIcons.calendar),
              const SizedBox(height: 12),
              _buildSeasonalPrices(),
            ],

            // Discount Card
            if (widget.discountPercentage > 0) ...[
              const SizedBox(height: 20),
              _buildDiscountCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainPriceCard() {
    final finalPrice = widget.discountPercentage > 0
        ? widget.basePrice.amount * (1 - widget.discountPercentage / 100)
        : widget.basePrice.amount;

    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue.withValues(
                  alpha: 0.15 + (0.05 * _pulseAnimationController.value),
                ),
                AppTheme.primaryPurple.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(
                  alpha: 0.2 + (0.1 * _pulseAnimationController.value),
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السعر الأساسي',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            (widget.basePrice.amount).toStringAsFixed(0),
                            style: AppTextStyles.displaySmall.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.basePrice.currency,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.pricingMethod.arabicLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Price Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withValues(alpha: 0.2),
                          AppTheme.primaryPurple.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.money_dollar_circle_fill,
                      size: 40,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
              if (widget.discountPercentage > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.tag_fill,
                        size: 16,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'السعر بعد الخصم: ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textLight,
                        ),
                      ),
                      Text(
                        '${finalPrice.toStringAsFixed(0)} ${widget.basePrice.currency}',
                        style: AppTextStyles.bodyMedium.copyWith(
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
        );
      },
    );
  }

  Widget _buildPricingOptions() {
    final options = [
      _PricingOption(
        title: 'يومي',
        price: widget.basePrice.amount,
        icon: CupertinoIcons.sun_max_fill,
        gradient: [AppTheme.warning, AppTheme.neonPurple],
      ),
      _PricingOption(
        title: 'أسبوعي',
        price: widget.basePrice.amount * 7 * 0.9,
        icon: CupertinoIcons.calendar_today,
        gradient: [AppTheme.primaryBlue, AppTheme.primaryCyan],
        discount: 10,
      ),
      _PricingOption(
        title: 'شهري',
        price: widget.basePrice.amount * 30 * 0.8,
        icon: CupertinoIcons.calendar,
        gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
        discount: 20,
      ),
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = _selectedPriceIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedPriceIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 140,
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: option.gradient)
                    : LinearGradient(
                        colors: option.gradient
                            .map((c) => c.withValues(alpha: 0.1))
                            .toList(),
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : option.gradient.first.withValues(alpha: 0.3),
                  width: isSelected ? 0 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: option.gradient.first.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        option.icon,
                        size: 20,
                        color:
                            isSelected ? Colors.white : option.gradient.first,
                      ),
                      if (option.discount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${option.discount}%',
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  isSelected ? Colors.white : AppTheme.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    option.title,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${option.price.toStringAsFixed(0)} ${widget.basePrice.currency}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeasonalPrices() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.5),
            AppTheme.darkCard.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: widget.seasonalPrices.map((seasonal) {
          return _buildSeasonalPriceItem(seasonal);
        }).toList(),
      ),
    );
  }

  Widget _buildSeasonalPriceItem(SeasonalPrice seasonal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: seasonal.gradient,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              seasonal.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seasonal.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  seasonal.dateRange,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${seasonal.price} ${widget.basePrice.currency}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: seasonal.gradient.first,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (seasonal.changePercentage != 0)
                Text(
                  '${seasonal.changePercentage > 0 ? '+' : ''}${seasonal.changePercentage}%',
                  style: AppTextStyles.caption.copyWith(
                    color: seasonal.changePercentage > 0
                        ? AppTheme.error
                        : AppTheme.success,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.success.withValues(alpha: 0.15),
            AppTheme.neonGreen.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.success, AppTheme.neonGreen],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.tag_fill,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خصم خاص',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'وفر ${(widget.basePrice.amount * widget.discountPercentage / 100).toStringAsFixed(0)} ${widget.basePrice.currency}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${widget.discountPercentage}%',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
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
    );
  }
}

// Helper Classes
class _PricingOption {
  final String title;
  final double price;
  final IconData icon;
  final List<Color> gradient;
  final int? discount;

  _PricingOption({
    required this.title,
    required this.price,
    required this.icon,
    required this.gradient,
    this.discount,
  });
}

class SeasonalPrice {
  final String name;
  final String dateRange;
  final double price;
  final int changePercentage;
  final IconData icon;
  final List<Color> gradient;

  SeasonalPrice({
    required this.name,
    required this.dateRange,
    required this.price,
    required this.changePercentage,
    required this.icon,
    required this.gradient,
  });
}
