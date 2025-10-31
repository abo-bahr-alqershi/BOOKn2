import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class PriceRangeSliderWidget extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final double minValue;
  final double maxValue;
  final String currency;
  final Function(double, double) onChanged;

  const PriceRangeSliderWidget({
    super.key,
    this.minPrice = 0,
    this.maxPrice = 100000,
    this.minValue = 0,
    this.maxValue = 100000,
    this.currency = 'YER',
    required this.onChanged,
  });

  @override
  State<PriceRangeSliderWidget> createState() => _PriceRangeSliderWidgetState();
}

class _PriceRangeSliderWidgetState extends State<PriceRangeSliderWidget>
    with TickerProviderStateMixin {
  late double _currentMinPrice;
  late double _currentMaxPrice;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _currentMinPrice = widget.minPrice;
    _currentMaxPrice = widget.maxPrice;
    _minController = TextEditingController(text: _formatPrice(_currentMinPrice));
    _maxController = TextEditingController(text: _formatPrice(_currentMaxPrice));
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceInputs(),
        const SizedBox(height: 32),
        _buildFuturisticSlider(),
        const SizedBox(height: 24),
        _buildQuickSelections(),
      ],
    );
  }

  Widget _buildPriceInputs() {
    return Row(
      children: [
        Expanded(
          child: _buildPriceInput(
            controller: _minController,
            label: 'الحد الأدنى',
            value: _currentMinPrice,
            isMin: true,
            onChanged: (value) {
              setState(() {
                _currentMinPrice = value.clamp(widget.minValue, _currentMaxPrice);
                widget.onChanged(_currentMinPrice, _currentMaxPrice);
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        _buildPriceConnector(),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPriceInput(
            controller: _maxController,
            label: 'الحد الأقصى',
            value: _currentMaxPrice,
            isMin: false,
            onChanged: (value) {
              setState(() {
                _currentMaxPrice = value.clamp(_currentMinPrice, widget.maxValue);
                widget.onChanged(_currentMinPrice, _currentMaxPrice);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInput({
    required TextEditingController controller,
    required String label,
    required double value,
    required bool isMin,
    required Function(double) onChanged,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.8),
                AppTheme.darkCard.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(_glowAnimation.value * 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(_glowAnimation.value * 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                            Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isMin ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 14,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      suffixText: widget.currency,
                      suffixStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    onChanged: (text) {
                      final number = double.tryParse(text.replaceAll(',', ''));
                      if (number != null) {
                        onChanged(number);
                        _pulseController.forward().then((_) {
                          _pulseController.reverse();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceConnector() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(_glowAnimation.value),
                AppTheme.primaryPurple.withOpacity(_glowAnimation.value * 0.5),
                Colors.transparent,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.horizontal_rule_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFuturisticSlider() {
    return Column(
      children: [
        // Slider Track Background
        Stack(
          alignment: Alignment.center,
          children: [
            // Background Glow Effect
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.primaryBlue.withOpacity(_glowAnimation.value * 0.1),
                        AppTheme.primaryPurple.withOpacity(_glowAnimation.value * 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Main Slider
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                trackHeight: 8,
                thumbColor: AppTheme.primaryBlue,
                overlayColor: AppTheme.primaryBlue.withOpacity(0.2),
                thumbShape: const _CustomThumbShape(), // أضف const هنا
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                rangeThumbShape: const _CustomRangeThumbShape(), // أضف const هنا
                rangeTrackShape: const _CustomRangeSliderTrackShape(),
                showValueIndicator: ShowValueIndicator.onlyForContinuous,
                valueIndicatorShape: _CustomValueIndicatorShape(),
                valueIndicatorTextStyle: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: RangeSlider(
                      values: RangeValues(_currentMinPrice, _currentMaxPrice),
                      min: widget.minValue,
                      max: widget.maxValue,
                      onChanged: (values) {
                        setState(() {
                          _currentMinPrice = values.start;
                          _currentMaxPrice = values.end;
                          _minController.text = _formatPrice(_currentMinPrice);
                          _maxController.text = _formatPrice(_currentMaxPrice);
                        });
                        widget.onChanged(_currentMinPrice, _currentMaxPrice);
                      },
                      labels: RangeLabels(
                        _formatPrice(_currentMinPrice),
                        _formatPrice(_currentMaxPrice),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        
        // Min/Max Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRangeLabel(_formatPrice(widget.minValue), true),
              _buildProgressIndicator(),
              _buildRangeLabel(_formatPrice(widget.maxValue), false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRangeLabel(String value, bool isMin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        value,
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentMaxPrice - _currentMinPrice) / (widget.maxValue - widget.minValue);
    
          return Expanded(
        child: Container(
          constraints: const BoxConstraints(minWidth: 0),
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickSelections() {
    final quickRanges = [
      {'label': 'أقل من 10K', 'min': 0.0, 'max': 10000.0, 'icon': Icons.savings},
      {'label': '10K - 25K', 'min': 10000.0, 'max': 25000.0, 'icon': Icons.account_balance_wallet},
      {'label': '25K - 50K', 'min': 25000.0, 'max': 50000.0, 'icon': Icons.account_balance},
      {'label': '50K - 100K', 'min': 50000.0, 'max': 100000.0, 'icon': Icons.business_center},
      {'label': 'أكثر من 100K', 'min': 100000.0, 'max': widget.maxValue, 'icon': Icons.diamond},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.flash_on_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'اختيارات سريعة',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickRanges.map((range) {
            final isSelected = _currentMinPrice == range['min'] && 
                              _currentMaxPrice == range['max'];
            
            return _buildQuickSelectionChip(
              label: range['label'] as String,
              icon: range['icon'] as IconData,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _currentMinPrice = range['min'] as double;
                  _currentMaxPrice = range['max'] as double;
                  _minController.text = _formatPrice(_currentMinPrice);
                  _maxController.text = _formatPrice(_currentMaxPrice);
                });
                widget.onChanged(_currentMinPrice, _currentMaxPrice);
                
                _pulseController.forward().then((_) {
                  _pulseController.reverse();
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickSelectionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: isSelected
            ? AppTheme.primaryGradient
            : LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.8),
                  AppTheme.darkCard.withOpacity(0.5),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textWhite,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }
}

// Custom Thumb Shape
class _CustomThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final double disabledThumbRadius;

  const _CustomThumbShape({
    this.enabledThumbRadius = 12,
    this.disabledThumbRadius = 10,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(isEnabled ? enabledThumbRadius : disabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    
    // Outer glow
    final glowPaint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 20, glowPaint);
    
    // Gradient background
    final gradient = Paint()
      ..shader = AppTheme.primaryGradient.createShader(
        Rect.fromCircle(center: center, radius: 12),
      );
    canvas.drawCircle(center, 12, gradient);
    
    // Inner white circle
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 6, innerPaint);
  }
}

// Custom Range Thumb Shape
class _CustomRangeThumbShape extends RangeSliderThumbShape {
  final double enabledThumbRadius;
  final double disabledThumbRadius;

  const _CustomRangeThumbShape({
    this.enabledThumbRadius = 12,
    this.disabledThumbRadius = 10,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(isEnabled ? enabledThumbRadius : disabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool isOnTop = false,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;
    
    // Outer glow
    final glowPaint = Paint()
      ..color = (thumb == Thumb.start ? AppTheme.primaryBlue : AppTheme.primaryPurple)
          .withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 20, glowPaint);
    
    // Gradient background - تصحيح هنا
    final gradientColors = thumb == Thumb.start
        ? [AppTheme.primaryBlue, AppTheme.primaryCyan]
        : [AppTheme.primaryPurple, AppTheme.primaryViolet];
    
    final gradient = Paint()
      ..shader = LinearGradient(colors: gradientColors).createShader(
        Rect.fromCircle(center: center, radius: 12),
      );
    canvas.drawCircle(center, 12, gradient);
    
    // Inner white circle
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 6, innerPaint);
  }
}
// Custom Range Slider Track Shape
// Custom Range Slider Track Shape - استبدل الكلاس بالكامل
class _CustomRangeSliderTrackShape extends RangeSliderTrackShape {
  const _CustomRangeSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    Offset? additionalActiveTrackStart,
    Offset? additionalActiveTrackEnd,
  }) {
    final Canvas canvas = context.canvas;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Background track
    final bgPaint = Paint()
      ..color = AppTheme.darkCard.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final bgRRect = RRect.fromRectAndRadius(
      trackRect,
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRRect, bgPaint);
    
    // Active track with gradient
    final double startPoint = additionalActiveTrackStart?.dx ?? startThumbCenter.dx;
    final double endPoint = additionalActiveTrackEnd?.dx ?? endThumbCenter.dx;
    
    final activeRect = Rect.fromPoints(
      Offset(startPoint, trackRect.top),
      Offset(endPoint, trackRect.bottom),
    );
    
    if (activeRect.width > 0) {
      final activePaint = Paint()
        ..shader = AppTheme.primaryGradient.createShader(activeRect)
        ..style = PaintingStyle.fill;
      
      final activeRRect = RRect.fromRectAndRadius(
        activeRect,
        const Radius.circular(4),
      );
      canvas.drawRRect(activeRRect, activePaint);
      
      // Glow effect
      final glowPaint = Paint()
        ..shader = AppTheme.primaryGradient.createShader(activeRect)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(activeRRect, glowPaint);
    }
  }
}

// Custom Value Indicator Shape
class _CustomValueIndicatorShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(0, 0);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    // No-op to hide the default value indicator and use custom labels
  }
}