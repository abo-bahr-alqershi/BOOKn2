import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class ReviewsSummaryWidget extends StatefulWidget {
  final String propertyId;
  final int reviewsCount;
  final double averageRating;
  final VoidCallback onViewAll;

  const ReviewsSummaryWidget({
    super.key,
    required this.propertyId,
    required this.reviewsCount,
    required this.averageRating,
    required this.onViewAll,
  });

  @override
  State<ReviewsSummaryWidget> createState() => _ReviewsSummaryWidgetState();
}

class _ReviewsSummaryWidgetState extends State<ReviewsSummaryWidget>
    with TickerProviderStateMixin {
  late AnimationController _chartController;
  late AnimationController _pulseController;
  late AnimationController _starController;
  late AnimationController _glowController;
  
  late Animation<double> _chartAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _starAnimation;
  
  final List<_AnimatedStar> _stars = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateStars();
    _startAnimations();
  }
  
  void _initializeAnimations() {
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _starController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutBack,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _starAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_starController);
  }
  
  void _generateStars() {
    for (int i = 0; i < 10; i++) {
      _stars.add(_AnimatedStar());
    }
  }
  
  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _chartController.forward();
      }
    });
  }

  @override
  void dispose() {
    _chartController.dispose();
    _pulseController.dispose();
    _starController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reviewsCount == 0) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        _buildAnimatedBackground(),
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFuturisticRatingSummary(),
              const SizedBox(height: 16),
              _buildFuturisticRatingBars(),
              const SizedBox(height: 16),
              _buildFuturisticRecentReviews(),
              const SizedBox(height: 12),
              _buildViewAllButton(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _starAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _StarBackgroundPainter(
              stars: _stars,
              animationValue: _starAnimation.value,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.warning.withOpacity(0.2),
                    AppTheme.warning.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _starAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _starAnimation.value,
                        child: Icon(
                          Icons.star_outline,
                          size: 48,
                          color: AppTheme.warning.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                  Icon(
                    Icons.rate_review_outlined,
                    size: 28,
                    color: AppTheme.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (bounds) => 
                  LinearGradient(
                    colors: [AppTheme.warning, AppTheme.warning.withOpacity(0.7)],
                  ).createShader(bounds),
              child: Text(
                'لا توجد تقييمات بعد',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'كن أول من يقيم هذا العقار',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            _buildGlowingButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
              },
              gradient: LinearGradient(
                colors: [AppTheme.warning, AppTheme.warning.withOpacity(0.7)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'اكتب أول تقييم',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticRatingSummary() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.warning.withOpacity(0.15),
                  AppTheme.warning.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.warning.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Row(
                  children: [
                    _buildRatingCircle(),
                    const SizedBox(width: 16),
                    Expanded(child: _buildRatingCategories()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRatingCircle() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            _getRatingColor(widget.averageRating),
            _getRatingColor(widget.averageRating).withOpacity(0.5),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getRatingColor(widget.averageRating).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _starAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: _CircleStarsPainter(
                  rotation: _starAnimation.value,
                  color: Colors.white.withOpacity(0.2),
                ),
                size: const Size(90, 90),
              );
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => 
                    LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white.withOpacity(0.9)],
                    ).createShader(bounds),
                child: Text(
                  widget.averageRating.toStringAsFixed(1),
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < widget.averageRating.round()
                        ? Icons.star
                        : Icons.star_outline,
                    size: 10,
                    color: Colors.white,
                  );
                }),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.reviewsCount} تقييم',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRatingCategories() {
    final categories = [
      {'label': 'النظافة', 'rating': 4.5, 'icon': Icons.cleaning_services},
      {'label': 'الخدمة', 'rating': 4.3, 'icon': Icons.room_service},
      {'label': 'الموقع', 'rating': 4.7, 'icon': Icons.location_on},
      {'label': 'القيمة', 'rating': 4.2, 'icon': Icons.attach_money},
    ];
    
    return Column(
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildFuturisticRatingCategory(
            category['label'] as String,
            category['rating'] as double,
            category['icon'] as IconData,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildFuturisticRatingCategory(String label, double rating, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 12,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 45,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontSize: 9,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedBuilder(
                animation: _chartAnimation,
                builder: (context, child) {
                  return Container(
                    height: 6,
                    width: (MediaQuery.of(context).size.width - 180) * 
                           (rating / 5) * _chartAnimation.value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getRatingColor(rating),
                          _getRatingColor(rating).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticRatingBars() {
    final ratingDistribution = [
      {'stars': 5, 'count': 45, 'percentage': 0.45},
      {'stars': 4, 'count': 30, 'percentage': 0.30},
      {'stars': 3, 'count': 15, 'percentage': 0.15},
      {'stars': 2, 'count': 7, 'percentage': 0.07},
      {'stars': 1, 'count': 3, 'percentage': 0.03},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Column(
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
                  Icons.bar_chart,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'توزيع التقييمات',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ratingDistribution.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            
            return AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildRatingBar(
                    data['stars'] as int,
                    data['count'] as int,
                    data['percentage'] as double,
                    index * 50,
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildRatingBar(int stars, int count, double percentage, int delay) {
    return Row(
      children: [
        SizedBox(
          width: 35,
          child: Row(
            children: [
              Text(
                stars.toString(),
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.star,
                size: 10,
                color: AppTheme.warning,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedBuilder(
                animation: _chartAnimation,
                builder: (context, child) {
                  final width = (MediaQuery.of(context).size.width - 120) * 
                                percentage * _chartAnimation.value;
                  
                  return Container(
                    height: 8,
                    width: width,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.warning,
                          AppTheme.warning.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            count.toString(),
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontSize: 9,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticRecentReviews() {
    final recentReviews = [
      {
        'userName': 'أحمد محمد',
        'rating': 4.5,
        'date': 'منذ 3 أيام',
        'comment': 'مكان رائع ونظيف، الخدمة ممتازة والموقع مميز.',
        'avatar': 'أ',
      },
      {
        'userName': 'فاطمة علي',
        'rating': 5.0,
        'date': 'منذ أسبوع',
        'comment': 'تجربة استثنائية! المكان يفوق التوقعات.',
        'avatar': 'ف',
      },
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
                Icons.message,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'أحدث التقييمات',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...recentReviews.map((review) => _buildFuturisticMiniReviewCard(
          userName: review['userName'] as String,
          rating: review['rating'] as double,
          date: review['date'] as String,
          comment: review['comment'] as String,
          avatar: review['avatar'] as String,
        )),
      ],
    );
  }

  Widget _buildFuturisticMiniReviewCard({
    required String userName,
    required double rating,
    required String date,
    required String comment,
    required String avatar,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatar,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      date,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getRatingColor(rating),
                      _getRatingColor(rating).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textLight,
              height: 1.4,
              fontSize: 10,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return Center(
      child: _buildGlowingButton(
        onPressed: widget.onViewAll,
        gradient: AppTheme.primaryGradient,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'عرض جميع التقييمات',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.reviewsCount.toString(),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward,
              size: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGlowingButton({
    required VoidCallback onPressed,
    required Widget child,
    required Gradient gradient,
  }) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradient.colors[0].withOpacity(0.25 + _glowController.value * 0.15),
                blurRadius: 15 + _glowController.value * 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                onPressed();
                HapticFeedback.mediumImpact();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: child,
              ),
            ),
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
}

// باقي الكلاسات بأحجام أصغر
class _AnimatedStar {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double opacity;
  
  _AnimatedStar() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    size = math.Random().nextDouble() * 2 + 0.5;
    speed = math.Random().nextDouble() * 0.0005 + 0.0002;
    opacity = math.Random().nextDouble() * 0.2 + 0.05;
  }
  
  void update() {
    y -= speed;
    if (y < 0) {
      y = 1.0;
      x = math.Random().nextDouble();
    }
  }
}

class _StarBackgroundPainter extends CustomPainter {
  final List<_AnimatedStar> stars;
  final double animationValue;
  
  _StarBackgroundPainter({
    required this.stars,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      star.update();
      
      final paint = Paint()
        ..color = AppTheme.warning.withOpacity(star.opacity)
        ..style = PaintingStyle.fill;
      
      _drawStar(
        canvas,
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }
  
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const spikes = 5;
    const step = math.pi / spikes;
    
    for (int i = 0; i < spikes * 2; i++) {
      final r = i.isEven ? radius : radius / 2;
      final angle = i * step;
      final x = center.dx + r * math.cos(angle - math.pi / 2);
      final y = center.dy + r * math.sin(angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CircleStarsPainter extends CustomPainter {
  final double rotation;
  final Color color;
  
  _CircleStarsPainter({
    required this.rotation,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;
    
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72) * math.pi / 180 + rotation;
      final starCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      _drawStar(canvas, starCenter, 6, Paint()..color = color);
    }
  }
  
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const spikes = 5;
    const step = math.pi / spikes;
    
    for (int i = 0; i < spikes * 2; i++) {
      final r = i.isEven ? radius : radius / 2;
      final angle = i * step;
      final x = center.dx + r * math.cos(angle - math.pi / 2);
      final y = center.dy + r * math.sin(angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}