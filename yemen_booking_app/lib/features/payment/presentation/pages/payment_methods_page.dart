import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/payment_method_enum.dart';
import '../widgets/payment_method_card_widget.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _itemsAnimationController;
  late AnimationController _floatingAnimationController;
  late AnimationController _particleAnimationController;
  
  // Animations
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _scaleAnimation;
  late List<Animation<double>> _itemAnimations;
  
  // Data
  final List<PaymentMethod> _savedMethods = [];
  final List<PaymentMethod> _availableMethods = PaymentMethod.values;
  
  // Particles for background
  final List<_FloatingParticle> _particles = [];
  
  // Scroll Controller
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingHeader = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _loadSavedMethods();
    _startAnimations();
    _scrollController.addListener(_onScroll);
  }

  void _initializeAnimations() {
    // Background Animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    // Header Animation
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));
    
    // Items Animation
    _itemsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _itemsAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _itemAnimations = List.generate(
      _availableMethods.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _itemsAnimationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutBack,
          ),
        ),
      ),
    );
    
    // Floating Animation
    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    // Particle Animation
    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }
  
  void _generateParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(_FloatingParticle());
    }
  }
  
  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _headerAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _itemsAnimationController.forward();
      });
    });
  }
  
  void _onScroll() {
    final shouldShow = _scrollController.offset > 200;
    if (shouldShow != _showFloatingHeader) {
      setState(() {
        _showFloatingHeader = shouldShow;
      });
    }
  }
  
  void _loadSavedMethods() {
    // Load saved payment methods from local storage or API
    // Example: Add some mock saved methods
    // setState(() {
    //   _savedMethods.add(PaymentMethod.creditCard);
    // });
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _headerAnimationController.dispose();
    _itemsAnimationController.dispose();
    _floatingAnimationController.dispose();
    _particleAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),
          
          // Floating Particles
          _buildParticles(),
          
          // Main Content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildFuturisticAppBar(),
              _buildGlowingHeader(),
              if (_savedMethods.isNotEmpty) _buildSavedMethodsSection(),
              _buildAvailableMethodsSection(),
              _buildSecurityInfoSection(),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
          
          // Floating Header
          if (_showFloatingHeader) _buildFloatingHeader(),
          
          // Floating Action Button
          _buildFuturisticFAB(),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
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
                AppTheme.darkBackground3.withOpacity(0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _BackgroundPatternPainter(
              animationValue: _backgroundAnimationController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
  
  Widget _buildParticles() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleAnimationController,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              animationValue: _particleAnimationController.value,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFuturisticAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _headerFadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _headerFadeAnimation,
              child: SlideTransition(
                position: _headerSlideAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Animated Circles
                      Positioned(
                        right: -50,
                        top: 50,
                        child: AnimatedBuilder(
                          animation: _floatingAnimationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_floatingAnimationController.value * 0.1),
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppTheme.primaryPurple.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Center Content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Glowing Icon Container
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    color: AppTheme.darkCard.withOpacity(0.3),
                                    child: const Icon(
                                      Icons.payment,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(bounds),
                              child: Text(
                                'طرق الدفع',
                                style: AppTextStyles.displaySmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              'اختر الطريقة المناسبة لك',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textMuted,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      leading: _buildGlassBackButton(),
      actions: [
        _buildGlassActionButton(
          icon: Icons.history,
          onPressed: () => context.push('/payment/history'),
        ),
      ],
    );
  }
  
  Widget _buildGlassBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.6),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: AppTheme.textWhite,
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlassActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.6),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(icon, size: 20),
              color: AppTheme.textWhite,
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlowingHeader() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.5),
                    AppTheme.darkCard.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'دفع آمن وسريع',
                                  style: AppTextStyles.heading2.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textWhite,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'جميع المعاملات محمية بأحدث تقنيات التشفير',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Security Features
                      Row(
                        children: [
                          _buildSecurityFeature(
                            icon: Icons.security,
                            label: 'SSL 256-bit',
                          ),
                          const SizedBox(width: 16),
                          _buildSecurityFeature(
                            icon: Icons.verified_user,
                            label: 'PCI DSS',
                          ),
                          const SizedBox(width: 16),
                          _buildSecurityFeature(
                            icon: Icons.lock,
                            label: '3D Secure',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSecurityFeature({
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.success.withOpacity(0.1),
              AppTheme.success.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.success.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.success,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.success,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSavedMethodsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bookmark,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'الطرق المحفوظة',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                    ),
                  ),
                ],
              ),
            ),
            ..._savedMethods.map((method) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PaymentMethodCardWidget(
                paymentMethod: method,
                isSaved: true,
                onTap: () => _selectPaymentMethod(method),
                onDelete: () => _deleteSavedMethod(method),
              ),
            )),
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.primaryBlue.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvailableMethodsSection() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return AnimatedBuilder(
              animation: _itemAnimations[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: _itemAnimations[index].value,
                  child: Opacity(
                    opacity: _itemAnimations[index].value.clamp(0.0, 1.0).toDouble(),
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        30 * (1 - _itemAnimations[index].value),
                      ),
                      child: child,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PaymentMethodCardWidget(
                  paymentMethod: _availableMethods[index],
                  isSaved: false,
                  onTap: () => _selectPaymentMethod(_availableMethods[index]),
                ),
              ),
            );
          },
          childCount: _availableMethods.length,
        ),
      ),
    );
  }
  
  Widget _buildSecurityInfoSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.info.withOpacity(0.1),
              AppTheme.info.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.info.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.info.withOpacity(0.3),
                    AppTheme.info.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: AppTheme.info,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حماية كاملة لبياناتك',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.info,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'نستخدم أحدث معايير الأمان العالمية لحماية معلوماتك المالية',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
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
  
  Widget _buildFloatingHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkCard.withOpacity(0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildGlassBackButton(),
                    const SizedBox(width: 16),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'طرق الدفع',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_availableMethods.length} طريقة',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFuturisticFAB() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _floatingAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatingAnimationController.value * 5),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/payment/add-method'),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_card,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'إضافة طريقة دفع',
                          style: AppTextStyles.buttonLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
  
  void _selectPaymentMethod(PaymentMethod method) {
    HapticFeedback.lightImpact();
    
    if (method == PaymentMethod.creditCard) {
      context.push('/payment/add-method', extra: method);
    } else if (method.isWallet) {
      _showWalletDialog(method);
    } else {
      Navigator.pop(context, method);
    }
  }
  
  void _showWalletDialog(PaymentMethod method) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildFuturisticWalletModal(ctx, method),
    );
  }
  
  Widget _buildFuturisticWalletModal(BuildContext ctx, PaymentMethod method) {
    return Container(
      height: MediaQuery.of(ctx).size.height * 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkCard,
            AppTheme.darkSurface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Icon and Title
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getMethodColor(method).withOpacity(0.3),
                              _getMethodColor(method).withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getMethodIcon(method),
                          size: 40,
                          color: _getMethodColor(method),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            LinearGradient(
                              colors: [
                                _getMethodColor(method),
                                _getMethodColor(method).withOpacity(0.7),
                              ],
                            ).createShader(bounds),
                        child: Text(
                          method.displayNameAr,
                          style: AppTextStyles.heading2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Wallet Number Field
                      _buildGlassTextField(
                        label: 'رقم المحفظة',
                        hint: 'أدخل رقم المحفظة',
                        icon: Icons.phone_android,
                        keyboardType: TextInputType.phone,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // PIN Field
                      _buildGlassTextField(
                        label: 'رمز التحقق',
                        hint: 'أدخل رمز التحقق',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Confirm Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getMethodColor(method),
                              _getMethodColor(method).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _getMethodColor(method).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(ctx);
                              Navigator.pop(context, method);
                              _showSuccessAnimation();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Text(
                                'تأكيد وإضافة',
                                style: AppTextStyles.buttonLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
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
  
  Widget _buildGlassTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLength: maxLength,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                icon,
                color: AppTheme.primaryBlue,
              ),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              counterText: '',
            ),
          ),
        ),
      ),
    );
  }
  
  void _deleteSavedMethod(PaymentMethod method) {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _buildFuturisticDeleteDialog(ctx, method),
    );
  }
  
  Widget _buildFuturisticDeleteDialog(BuildContext ctx, PaymentMethod method) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkCard.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.error.withOpacity(0.2),
                          AppTheme.error.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 40,
                      color: AppTheme.error,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    'حذف طريقة الدفع',
                    style: AppTextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.error,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    'هل أنت متأكد من حذف ${method.displayNameAr}؟',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.darkBorder,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Text(
                                  'إلغاء',
                                  style: AppTextStyles.buttonMedium.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.error,
                                AppTheme.error.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.error.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _savedMethods.remove(method);
                                });
                                Navigator.pop(ctx);
                                _showSuccessSnackBar('تم حذف طريقة الدفع بنجاح');
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Text(
                                  'حذف',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showSuccessAnimation() {
    // Implementation for success animation
    _showSuccessSnackBar('تمت إضافة طريقة الدفع بنجاح');
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.success.withOpacity(0.8),
                      AppTheme.success,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  Color _getMethodColor(PaymentMethod method) {
    switch (method) {
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
  
  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
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
}

// Background Pattern Painter
class _BackgroundPatternPainter extends CustomPainter {
  final double animationValue;
  
  _BackgroundPatternPainter({required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Draw animated grid
    const spacing = 50.0;
    final offset = animationValue * spacing;
    
    paint.shader = LinearGradient(
      colors: [
        AppTheme.primaryBlue.withOpacity(0.1),
        AppTheme.primaryPurple.withOpacity(0.05),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Vertical lines
    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Horizontal lines
    for (double y = -spacing + offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Floating Particle Model
class _FloatingParticle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double radius;
  late double opacity;
  late Color color;
  
  _FloatingParticle() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.002;
    vy = (math.Random().nextDouble() - 0.5) * 0.002;
    radius = math.Random().nextDouble() * 3 + 1;
    opacity = math.Random().nextDouble() * 0.5 + 0.1;
    
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }
  
  void update() {
    x += vx;
    y += vy;
    
    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;
  }
}

// Particle Painter
class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double animationValue;
  
  _ParticlePainter({
    required this.particles,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();
      
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}