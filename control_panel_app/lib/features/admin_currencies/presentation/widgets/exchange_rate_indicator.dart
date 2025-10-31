// lib/features/admin_currencies/presentation/widgets/exchange_rate_indicator.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/currency.dart';

class ExchangeRateIndicator extends StatefulWidget {
  final Currency baseCurrency;
  final List<Currency> currencies;

  const ExchangeRateIndicator({
    super.key,
    required this.baseCurrency,
    required this.currencies,
  });

  @override
  State<ExchangeRateIndicator> createState() => _ExchangeRateIndicatorState();
}

class _ExchangeRateIndicatorState extends State<ExchangeRateIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _scrollController;
  late PageController _pageController;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pageController = PageController(viewportFraction: 0.9);

    // Auto scroll
    if (widget.currencies.isNotEmpty) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final nextIndex = (_currentIndex + 1) % widget.currencies.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() => _currentIndex = nextIndex);
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currencies.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          height: 80,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryCyan.withValues(alpha: 0.05),
                      AppTheme.primaryBlue.withValues(alpha: 0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),

              // Content
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    children: [
                      // Base currency indicator
                      _buildBaseCurrencySection(),

                      // Divider
                      Container(
                        width: 1,
                        height: 50,
                        color: AppTheme.darkBorder.withValues(alpha: 0.2),
                      ),

                      // Exchange rates carousel
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                          },
                          itemCount: widget.currencies.length,
                          itemBuilder: (context, index) {
                            return _buildExchangeRateItem(
                              widget.currencies[index],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBaseCurrencySection() {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.success, AppTheme.neonGreen],
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                _getCurrencySymbol(widget.baseCurrency.code),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.baseCurrency.arabicCode,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeRateItem(Currency currency) {
    final rate = currency.exchangeRate ?? 1.0;
    final isUp = math.Random().nextBool(); // Simulate trend

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Currency info
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currency.arabicCode,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                const SizedBox(height: 1),
                Text(
                  currency.code,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Exchange rate with trend
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rate.toStringAsFixed(4),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppTheme.primaryCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isUp
                        ? CupertinoIcons.arrow_up_right
                        : CupertinoIcons.arrow_down_right,
                    size: 12,
                    color: isUp ? AppTheme.success : AppTheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 0),
              Text(
                isUp ? '+0.25%' : '-0.12%',
                style: AppTextStyles.caption.copyWith(
                  color: isUp ? AppTheme.success : AppTheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCurrencySymbol(String code) {
    final symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'YER': '﷼',
      'SAR': '﷼',
      'AED': 'د.إ',
      'KWD': 'د.ك',
      'QAR': 'ر.ق',
      'OMR': 'ر.ع',
      'BHD': 'د.ب',
      'JOD': 'د.أ',
      'EGP': 'ج.م',
      'LBP': 'ل.ل',
    };
    return symbols[code] ?? code.substring(0, 1);
  }
}
