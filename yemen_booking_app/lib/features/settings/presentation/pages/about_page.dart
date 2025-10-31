import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _particleAnimationController;
  late AnimationController _glowAnimationController;
  
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  PackageInfo? _packageInfo;
  
  final List<FeatureItem> _features = [
    FeatureItem(
      icon: Icons.search_rounded,
      title: 'بحث متقدم',
      description: 'ابحث بسهولة عن الفنادق والوحدات المناسبة',
      gradient: LinearGradient(
        colors: [AppTheme.primaryBlue, AppTheme.primaryCyan],
      ),
    ),
    FeatureItem(
      icon: Icons.security_rounded,
      title: 'حجز آمن',
      description: 'نظام دفع آمن ومشفر لحماية معلوماتك',
      gradient: LinearGradient(
        colors: [AppTheme.success, AppTheme.neonGreen],
      ),
    ),
    FeatureItem(
      icon: Icons.support_agent_rounded,
      title: 'دعم 24/7',
      description: 'فريق دعم متخصص لمساعدتك في أي وقت',
      gradient: LinearGradient(
        colors: [AppTheme.primaryPurple, AppTheme.primaryViolet],
      ),
    ),
    FeatureItem(
      icon: Icons.star_rounded,
      title: 'تقييمات موثوقة',
      description: 'تقييمات حقيقية من نزلاء سابقين',
      gradient: LinearGradient(
        colors: [AppTheme.warning, Colors.orange],
      ),
    ),
  ];
  
  final List<SocialMedia> _socialMedia = [
    SocialMedia(
      icon: Icons.facebook,
      name: 'Facebook',
      url: 'https://facebook.com/yemenbooking',
      color: const Color(0xFF1877F2),
    ),
    SocialMedia(
      icon: Icons.telegram,
      name: 'Telegram',
      url: 'https://t.me/yemenbooking',
      color: const Color(0xFF0088CC),
    ),
    SocialMedia(
      icon: Icons.alternate_email,
      name: 'X (Twitter)',
      url: 'https://twitter.com/yemenbooking',
      color: AppTheme.textWhite,
    ),
    SocialMedia(
      icon: Icons.camera_alt,
      name: 'Instagram',
      url: 'https://instagram.com/yemenbooking',
      color: const Color(0xFFE4405F),
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _logoAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _logoRotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.linear,
    ));
    
    _logoScaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));
    
    _loadPackageInfo();
    _contentAnimationController.forward();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _contentAnimationController.dispose();
    _particleAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
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
          _buildFloatingParticles(),
          
          // Main Content
          CustomScrollView(
            slivers: [
              _buildFuturisticAppBar(),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _logoRotationAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_logoRotationAnimation.value),
                math.sin(_logoRotationAnimation.value),
              ),
              end: Alignment(
                -math.cos(_logoRotationAnimation.value),
                -math.sin(_logoRotationAnimation.value),
              ),
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2,
                AppTheme.darkBackground3,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(
            animationValue: _particleAnimationController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFuturisticAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryPurple.withOpacity(0.3),
                AppTheme.primaryBlue.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: AppTheme.darkCard.withOpacity(0.3),
                child: Center(
                  child: _buildAnimatedLogo(),
                ),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.7),
                AppTheme.darkCard.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.textWhite,
            size: 18,
          ),
        ),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 3D Logo Container
        AnimatedBuilder(
          animation: Listenable.merge([
            _logoRotationAnimation,
            _logoScaleAnimation,
            _glowAnimationController,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _logoScaleAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow Effect
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(
                            0.3 + (_glowAnimationController.value * 0.2),
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  
                  // Rotating Ring
                  Transform.rotate(
                    angle: _logoRotationAnimation.value,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.3),
                            AppTheme.primaryPurple.withOpacity(0.5),
                            AppTheme.primaryCyan.withOpacity(0.3),
                            AppTheme.primaryBlue.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Main Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.hotel_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        ShaderMask(
          shaderCallback: (bounds) => 
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            AppConstants.appName,
            style: AppTextStyles.heading1.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'منصتك الموثوقة للحجوزات في اليمن',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 30),
          
          // Description Card
          _buildFuturisticCard(
            title: 'نبذة عن التطبيق',
            icon: Icons.info_rounded,
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryCyan],
            ),
            child: Text(
              '''تطبيق يمن بوكينج هو المنصة الرائدة للحجوزات الفندقية والسياحية في اليمن. نسعى لتوفير تجربة حجز سهلة وموثوقة، مع مجموعة واسعة من الخيارات التي تناسب جميع الاحتياجات والميزانيات.

نعمل مع أفضل الفنادق والمنشآت السياحية في جميع أنحاء اليمن لضمان حصولك على أفضل الأسعار والخدمات. سواء كنت تبحث عن إقامة فاخرة أو خيارات اقتصادية، ستجد ما يناسبك معنا.''',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
                height: 1.7,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Features Section
          _buildFeaturesSection(),
          
          const SizedBox(height: 24),
          
          // Contact Section
          _buildContactSection(),
          
          const SizedBox(height: 24),
          
          // Social Media Section
          _buildSocialMediaSection(),
          
          const SizedBox(height: 24),
          
          // Legal Section
          _buildLegalSection(),
          
          const SizedBox(height: 40),
          
          // Version Info
          _buildVersionInfo(),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFuturisticCard({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gradient.colors[0].withOpacity(0.3),
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
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: gradient.scale(0.3),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return _buildFuturisticCard(
      title: 'المميزات الرئيسية',
      icon: Icons.star_rounded,
      gradient: LinearGradient(
        colors: [AppTheme.primaryPurple, AppTheme.primaryViolet],
      ),
      child: Column(
        children: _features.map((feature) {
          final index = _features.indexOf(feature);
          
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 100)),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(30 * (1 - value), 0),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0).toDouble(),
                  child: _buildFeatureItem(feature),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeatureItem(FeatureItem feature) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            feature.gradient.colors[0].withOpacity(0.1),
            feature.gradient.colors[1].withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: feature.gradient.colors[0].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: feature.gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: feature.gradient.colors[0].withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              feature.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildFuturisticCard(
      title: 'تواصل معنا',
      icon: Icons.contact_support_rounded,
      gradient: LinearGradient(
        colors: [AppTheme.info, AppTheme.primaryBlue],
      ),
      child: Column(
        children: [
          _buildContactItem(
            icon: Icons.email_rounded,
            label: 'البريد الإلكتروني',
            value: 'support@yemenbooking.com',
            onTap: () => _launchUrl('mailto:support@yemenbooking.com'),
          ),
          _buildContactItem(
            icon: Icons.phone_rounded,
            label: 'الهاتف',
            value: '+967 777 123 456',
            onTap: () => _launchUrl('tel:+967777123456'),
          ),
          _buildContactItem(
            icon: Icons.language_rounded,
            label: 'الموقع الإلكتروني',
            value: 'www.yemenbooking.com',
            onTap: () => _launchUrl('https://www.yemenbooking.com'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.3),
              AppTheme.darkCard.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return _buildFuturisticCard(
      title: 'تابعنا على',
      icon: Icons.share_rounded,
      gradient: LinearGradient(
        colors: [AppTheme.neonGreen, AppTheme.success],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _socialMedia.map((social) {
          return _buildSocialButton(social);
        }).toList(),
      ),
    );
  }

  Widget _buildSocialButton(SocialMedia social) {
    return GestureDetector(
      onTap: () => _launchUrl(social.url),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              social.color.withOpacity(0.2),
              social.color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: social.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            social.icon,
            color: social.color,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildLegalSection() {
    return Column(
      children: [
        _buildLegalItem(
          icon: Icons.description_outlined,
          title: 'الشروط والأحكام',
          onTap: () {
            // Navigate to terms page
          },
        ),
        _buildLegalItem(
          icon: Icons.privacy_tip_outlined,
          title: 'سياسة الخصوصية',
          onTap: () => context.push('/settings/privacy-policy'),
        ),
        _buildLegalItem(
          icon: Icons.copyright_outlined,
          title: 'حقوق الطبع والنشر',
          onTap: () => _showCopyrightDialog(),
        ),
      ],
    );
  }

  Widget _buildLegalItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryPurple,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppTheme.textWhite,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'الإصدار',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => 
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              '${_packageInfo?.version ?? AppConstants.appVersion} (${_packageInfo?.buildNumber ?? AppConstants.appBuildNumber})',
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'صُنع بـ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              ShaderMask(
                shaderCallback: (bounds) => 
                    const LinearGradient(
                      colors: [Colors.red, Colors.pink],
                    ).createShader(bounds),
                child: const Icon(
                  Icons.favorite,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'في اليمن',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCopyrightDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: AppTheme.darkCard.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          title: ShaderMask(
            shaderCallback: (bounds) => 
                AppTheme.primaryGradient.createShader(bounds),
            child: const Text(
              'حقوق الطبع والنشر',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Text(
            'جميع الحقوق محفوظة © 2024 يمن بوكينج',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Text(
                      'حسناً',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن فتح الرابط: $url'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}

// Models
class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;

  FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

class SocialMedia {
  final IconData icon;
  final String name;
  final String url;
  final Color color;

  SocialMedia({
    required this.icon,
    required this.name,
    required this.url,
    required this.color,
  });
}

// Particles Painter
class _ParticlesPainter extends CustomPainter {
  final double animationValue;
  
  _ParticlesPainter({required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 20; i++) {
      final x = (i * size.width / 20) + (animationValue * size.width);
      final y = size.height * (0.2 + math.sin(animationValue * 2 * math.pi + i) * 0.3);
      
      paint.shader = RadialGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(x % size.width, y),
        radius: 3,
      ));
      
      canvas.drawCircle(
        Offset(x % size.width, y),
        3 + (i % 3),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}