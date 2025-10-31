import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/price_widget.dart';
import '../widgets/price_breakdown_widget.dart';

class BookingSummaryPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const BookingSummaryPage({
    super.key,
    required this.bookingData,
  });

  @override
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _shimmerAnimationController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  // Calculated values
  late int nights;
  late double pricePerNight;
  late double totalPrice;
  late double servicesTotal;
  late double tax;
  late double grandTotal;

  @override
  void initState() {
    super.initState();
    _calculatePrices();
    _initializeAnimations();
    _startAnimations();
  }

  void _calculatePrices() {
    final checkIn = widget.bookingData['checkIn'] as DateTime;
    final checkOut = widget.bookingData['checkOut'] as DateTime;
    nights = checkOut.difference(checkIn).inDays;
    pricePerNight = (widget.bookingData['pricePerNight'] ?? 0.0) as double;
    totalPrice = nights * pricePerNight;
    
    final services = widget.bookingData['selectedServices'] as List<Map<String, dynamic>>;
    servicesTotal = services.fold<double>(
      0,
      (sum, service) => sum + (service['price'] as num).toDouble(),
    );
    
    tax = (totalPrice + servicesTotal) * 0.05;
    grandTotal = totalPrice + servicesTotal + tax;
  }

  void _initializeAnimations() {
    // Slow background animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    // Card Animation
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOut,
    ));
    
    // Shimmer Animation
    _shimmerAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }
  
  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _cardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _cardAnimationController.dispose();
    _shimmerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildMinimalAppBar(),
      body: Stack(
        children: [
          // Subtle animated background
          _buildSubtleBackground(),
          
          // Subtle particles
          _buildSubtleParticles(),
          
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: AnimatedBuilder(
                animation: _cardAnimationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildCompactPropertyCard(),
                            const SizedBox(height: 12),
                            _buildCompactBookingDetails(),
                            const SizedBox(height: 12),
                            _buildCompactGuestDetails(),
                            const SizedBox(height: 12),
                            if (widget.bookingData['selectedServices'].isNotEmpty) ...[
                              _buildCompactServicesCard(),
                              const SizedBox(height: 12),
                            ],
                            if (widget.bookingData['specialRequests']?.isNotEmpty ?? false) ...[
                              _buildCompactSpecialRequestsCard(),
                              const SizedBox(height: 12),
                            ],
                            _buildCompactPriceBreakdown(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildMinimalBottomBar(),
    );
  }

  PreferredSizeWidget _buildMinimalAppBar() {
    return AppBar(
      backgroundColor: AppTheme.darkCard.withOpacity(0.5),
      elevation: 0,
      toolbarHeight: 56,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: _buildMinimalBackButton(),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الحجز',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textWhite.withOpacity(0.95),
            ),
          ),
          Text(
            'الخطوة 2 من 3',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          height: 2,
          child: LinearProgressIndicator(
            value: 0.66,
            backgroundColor: AppTheme.darkBorder.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryBlue.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              color: AppTheme.textWhite.withOpacity(0.9),
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtleBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2,
                AppTheme.darkBackground3,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _SubtleWavePainter(
              animationValue: _backgroundAnimationController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildSubtleParticles() {
    return AnimatedBuilder(
      animation: _shimmerAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _SubtleFloatingParticlesPainter(
            animationValue: _shimmerAnimationController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildCompactPropertyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildCompactPropertyImage(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.bookingData['propertyName'],
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textWhite.withOpacity(0.95),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppTheme.primaryCyan.withOpacity(0.7),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'صنعاء، اليمن',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted.withOpacity(0.7),
                                fontSize: 10,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPropertyImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.2),
            AppTheme.primaryPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              child: Center(
                child: Icon(
                  Icons.apartment_rounded,
                  color: AppTheme.primaryBlue.withOpacity(0.5),
                  size: 28,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _shimmerAnimationController,
              builder: (context, child) {
                return Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1 + _shimmerAnimationController.value * 0.5, -1),
                        end: Alignment(-0.5 + _shimmerAnimationController.value * 0.5, 1),
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBookingDetails() {
    final checkIn = widget.bookingData['checkIn'] as DateTime;
    final checkOut = widget.bookingData['checkOut'] as DateTime;
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _buildCompactDetailRow(
                  icon: Icons.calendar_today_rounded,
                  iconColor: AppTheme.primaryBlue.withOpacity(0.8),
                  label: 'تاريخ الوصول',
                  value: dateFormat.format(checkIn),
                ),
                _buildSubtleDivider(),
                _buildCompactDetailRow(
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppTheme.primaryPurple.withOpacity(0.8),
                  label: 'تاريخ المغادرة',
                  value: dateFormat.format(checkOut),
                ),
                _buildSubtleDivider(),
                _buildCompactDetailRow(
                  icon: Icons.nights_stay_rounded,
                  iconColor: AppTheme.primaryCyan.withOpacity(0.8),
                  label: 'عدد الليالي',
                  value: '$nights ${nights == 1 ? 'ليلة' : 'ليالي'}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactGuestDetails() {
    final adultsCount = widget.bookingData['adultsCount'] as int;
    final childrenCount = widget.bookingData['childrenCount'] as int;
    final totalGuests = adultsCount + childrenCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neonGreen.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: _buildCompactDetailRow(
              icon: Icons.people_outline_rounded,
              iconColor: AppTheme.neonGreen.withOpacity(0.8),
              label: 'عدد الضيوف',
              value: '$totalGuests ضيف ($adultsCount بالغ${childrenCount > 0 ? '، $childrenCount طفل' : ''})',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactServicesCard() {
    final services = widget.bookingData['selectedServices'] as List<Map<String, dynamic>>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryViolet.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryViolet.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryViolet.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.room_service_rounded,
                        color: AppTheme.primaryViolet.withOpacity(0.8),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الخدمات الإضافية',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...services.map((service) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryViolet.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            service['name'],
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${service['price']} ريال',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryViolet.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSpecialRequestsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.info.withOpacity(0.8),
                    size: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طلبات خاصة',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.info.withOpacity(0.9),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.bookingData['specialRequests'],
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPriceBreakdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: PriceBreakdownWidget(
        nights: nights,
        pricePerNight: pricePerNight,
        servicesTotal: servicesTotal,
        taxRate: 0.05,
        currency: 'ريال',
      ),
    );
  }

  Widget _buildCompactDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 14,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textWhite.withOpacity(0.9),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtleDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.darkBorder.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCompactTotalPriceRow(),
                  const SizedBox(height: 10),
                  _buildCompactContinueButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTotalPriceRow() {
    return Row(
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
          price: grandTotal,
          currency: 'ريال',
          displayType: PriceDisplayType.normal,
          priceStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppTheme.primaryBlue.withOpacity(0.9),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactContinueButton() {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.selectionClick(),
      onTap: _navigateToPayment,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlue.withOpacity(0.9),
              AppTheme.primaryPurple.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _navigateToPayment,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.payment_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'المتابعة إلى الدفع',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPayment() {
    HapticFeedback.mediumImpact();
    context.push('/booking/payment', extra: widget.bookingData);
  }
}

// Subtle Wave Painter
class _SubtleWavePainter extends CustomPainter {
  final double animationValue;
  
  _SubtleWavePainter({
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;
    
    for (int i = 0; i < 3; i++) {
      paint.color = AppTheme.primaryBlue.withOpacity(0.02 + (i * 0.01));
      
      final path = Path();
      
      for (double x = 0; x < size.width; x++) {
        final y = size.height / 2 +
            math.sin((x / size.width * math.pi) + animationValue + (i * 0.5)) *
                (20 + i * 5);
        
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Subtle Floating Particles Painter
class _SubtleFloatingParticlesPainter extends CustomPainter {
  final double animationValue;
  
  _SubtleFloatingParticlesPainter({required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (int i = 0; i < 8; i++) {
      final x = (math.sin(animationValue * math.pi + i) + 1) / 2 * size.width;
      final y = ((animationValue + i * 0.1) % 1) * size.height;
      final opacity = math.sin(animationValue * math.pi + i).abs() * 0.1;
      final radius = 1 + math.sin(animationValue * math.pi + i).abs() * 2;
      
      paint.color = AppTheme.primaryBlue.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}