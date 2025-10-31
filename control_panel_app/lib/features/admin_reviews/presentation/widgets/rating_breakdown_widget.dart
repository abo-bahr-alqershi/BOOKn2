// lib/features/admin_reviews/presentation/widgets/rating_breakdown_widget.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class RatingBreakdownWidget extends StatefulWidget {
  final double cleanliness;
  final double service;
  final double location;
  final double value;
  final bool isDesktop;
  
  const RatingBreakdownWidget({
    super.key,
    required this.cleanliness,
    required this.service,
    required this.location,
    required this.value,
    required this.isDesktop,
  });
  
  @override
  State<RatingBreakdownWidget> createState() => _RatingBreakdownWidgetState();
}

class _RatingBreakdownWidgetState extends State<RatingBreakdownWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _progressAnimations;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressAnimations = [
      Tween<double>(begin: 0.0, end: widget.cleanliness / 5.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
        ),
      ),
      Tween<double>(begin: 0.0, end: widget.service / 5.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
        ),
      ),
      Tween<double>(begin: 0.0, end: widget.location / 5.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
        ),
      ),
      Tween<double>(begin: 0.0, end: widget.value / 5.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
    ];
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  double get _overallRating {
    return (widget.cleanliness + widget.service + widget.location + widget.value) / 4;
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkCard.withOpacity(0.7),
              AppTheme.darkCard.withOpacity(0.5),
            ],
          ),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                // الرأس مع التقييم الإجمالي
                Row(
                  children: [
                    // دائرة النتيجة الإجمالية
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: _overallRating),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Container(
                          width: widget.isDesktop ? 100 : 80,
                          height: widget.isDesktop ? 100 : 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _getRatingColor(value),
                                _getRatingColor(value).withOpacity(0.3),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getRatingColor(value).withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // دائرة التقدم في الخلفية
                              CustomPaint(
                                size: Size(
                                  widget.isDesktop ? 100 : 80,
                                  widget.isDesktop ? 100 : 80,
                                ),
                                painter: CircularProgressPainter(
                                  progress: value / 5.0,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                              // نص النتيجة
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    value.toStringAsFixed(1),
                                    style: AppTextStyles.heading2.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'من 5',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // نص التقييم والنجوم
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getRatingText(_overallRating),
                            style: AppTextStyles.heading3.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (index) {
                              final filled = index < _overallRating.floor();
                              final halfFilled = index == _overallRating.floor() && 
                                  _overallRating % 1 >= 0.5;
                              
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 300 + (index * 100)),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Icon(
                                      halfFilled
                                          ? Icons.star_half_rounded
                                          : filled
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                      color: AppTheme.warning,
                                      size: widget.isDesktop ? 28 : 24,
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // فئات التقييم
                if (widget.isDesktop || isTablet)
                  Row(
                    children: [
                      Expanded(
                        child: _buildRatingCategory(
                          'النظافة',
                          widget.cleanliness,
                          Icons.cleaning_services,
                          _progressAnimations[0],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRatingCategory(
                          'الخدمة',
                          widget.service,
                          Icons.room_service,
                          _progressAnimations[1],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildRatingCategory(
                        'النظافة',
                        widget.cleanliness,
                        Icons.cleaning_services,
                        _progressAnimations[0],
                      ),
                      const SizedBox(height: 12),
                      _buildRatingCategory(
                        'الخدمة',
                        widget.service,
                        Icons.room_service,
                        _progressAnimations[1],
                      ),
                    ],
                  ),
                
                const SizedBox(height: 12),
                
                if (widget.isDesktop || isTablet)
                  Row(
                    children: [
                      Expanded(
                        child: _buildRatingCategory(
                          'الموقع',
                          widget.location,
                          Icons.location_on,
                          _progressAnimations[2],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRatingCategory(
                          'القيمة',
                          widget.value,
                          Icons.attach_money,
                          _progressAnimations[3],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildRatingCategory(
                        'الموقع',
                        widget.location,
                        Icons.location_on,
                        _progressAnimations[2],
                      ),
                      const SizedBox(height: 12),
                      _buildRatingCategory(
                        'القيمة',
                        widget.value,
                        Icons.attach_money,
                        _progressAnimations[3],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRatingCategory(
    String label,
    double rating,
    IconData icon,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.inputBackground.withOpacity(0.3),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _getRatingColor(rating).withOpacity(0.2),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: _getRatingColor(rating),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textLight,
                          ),
                        ),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getRatingColor(rating),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: animation.value,
                        minHeight: 6,
                        backgroundColor: AppTheme.darkBorder.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getRatingColor(rating),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return AppTheme.success;
    if (rating >= 3.5) return AppTheme.warning;
    if (rating >= 2.5) return Colors.orange;
    return AppTheme.error;
  }
  
  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'ممتاز';
    if (rating >= 4.0) return 'جيد جداً';
    if (rating >= 3.5) return 'جيد';
    if (rating >= 3.0) return 'متوسط';
    if (rating >= 2.0) return 'دون المتوسط';
    return 'ضعيف';
  }
}

// رسام دائرة التقدم المخصصة
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  
  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // دائرة الخلفية
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // قوس التقدم
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}