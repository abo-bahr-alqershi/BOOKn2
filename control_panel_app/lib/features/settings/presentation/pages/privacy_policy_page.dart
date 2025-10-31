import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';

class PrivacyPolicyPage extends StatefulWidget {
  final bool isFirstTime;

  const PrivacyPolicyPage({
    super.key,
    this.isFirstTime = false,
  });

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage>
    with TickerProviderStateMixin {
  bool _acceptTerms = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _backgroundAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<PolicySection> _sections = [
    PolicySection(
      title: '1. مقدمة',
      icon: Icons.info_rounded,
      content: '''نحن في تطبيق حجوزات اليمن نحترم خصوصيتك ونلتزم بحماية معلوماتك الشخصية. توضح هذه السياسة كيفية جمع واستخدام وحماية المعلومات التي نحصل عليها منك.

هذه السياسة تنطبق على جميع المستخدمين لتطبيقنا وخدماتنا. باستخدامك للتطبيق، فإنك توافق على ممارساتنا الموضحة في هذه السياسة.''',
      gradient: LinearGradient(
        colors: [AppTheme.primaryBlue, AppTheme.primaryCyan],
      ),
      isExpanded: true,
    ),
    PolicySection(
      title: '2. المعلومات التي نجمعها',
      icon: Icons.data_usage_rounded,
      content: '''نقوم بجمع المعلومات التالية:

• المعلومات الشخصية: الاسم الكامل، البريد الإلكتروني، رقم الهاتف، تاريخ الميلاد
• معلومات الحساب: اسم المستخدم، كلمة المرور المشفرة، صورة الملف الشخصي
• معلومات الحجز: التواريخ، الوجهات، تفضيلات السكن، عدد الضيوف
• معلومات الدفع: تفاصيل البطاقة الائتمانية (مشفرة بالكامل)، سجل المعاملات
• معلومات الجهاز: نوع الجهاز، نظام التشغيل، معرف الجهاز، عنوان IP
• معلومات الاستخدام: الصفحات المزارة، الوقت المستغرق، التفاعلات''',
      gradient: LinearGradient(
        colors: [AppTheme.primaryPurple, AppTheme.primaryViolet],
      ),
    ),
    PolicySection(
      title: '3. كيف نستخدم معلوماتك',
      icon: Icons.settings_applications_rounded,
      content: '''نستخدم المعلومات المجمعة للأغراض التالية:

• معالجة الحجوزات وإتمام المعاملات
• التواصل معك بخصوص حجوزاتك وخدماتنا
• تحسين خدماتنا وتجربة المستخدم
• تخصيص المحتوى والعروض حسب اهتماماتك
• إرسال التحديثات والعروض الترويجية (بموافقتك)
• ضمان الأمان ومنع الاحتيال
• تحليل استخدام التطبيق لتحسين الأداء
• الامتثال للمتطلبات القانونية والتنظيمية''',
      gradient: LinearGradient(
        colors: [AppTheme.neonGreen, AppTheme.success],
      ),
    ),
    PolicySection(
      title: '4. مشاركة المعلومات',
      icon: Icons.share_rounded,
      content: '''لا نبيع أو نؤجر معلوماتك الشخصية لأطراف ثالثة. قد نشارك معلوماتك فقط في الحالات التالية:

• مع مقدمي الخدمات: الفنادق والمنشآت السياحية لإتمام الحجوزات
• مع شركاء الدفع: لمعالجة المعاملات المالية بشكل آمن
• للامتثال القانوني: عند الضرورة القانونية أو بأمر من المحكمة
• لحماية الحقوق: لحماية حقوقنا وحقوق المستخدمين الآخرين
• بموافقتك الصريحة: عندما توافق على مشاركة معلوماتك''',
      gradient: LinearGradient(
        colors: [AppTheme.warning, Colors.orange],
      ),
    ),
    PolicySection(
      title: '5. حماية المعلومات',
      icon: Icons.security_rounded,
      content: '''نحن نتخذ إجراءات أمنية مناسبة لحماية معلوماتك الشخصية:

• التشفير: نستخدم تشفير SSL/TLS لحماية البيانات المنقولة
• التحكم في الوصول: نقيد الوصول للموظفين المصرح لهم فقط
• المراقبة: نراقب أنظمتنا على مدار الساعة للكشف عن أي اختراقات
• التحديثات: نحدث إجراءاتنا الأمنية بانتظام
• النسخ الاحتياطي: نحتفظ بنسخ احتياطية آمنة لبياناتك
• المصادقة الثنائية: نوفر خيار المصادقة الثنائية لحسابك''',
      gradient: LinearGradient(
        colors: [AppTheme.info, AppTheme.primaryBlue],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _contentAnimationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _backgroundAnimationController.dispose();
    _contentAnimationController.dispose();
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
          
          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildFuturisticHeader(),
                
                // Last Updated Banner
                _buildUpdateBanner(),
                
                // Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildPolicyContent(),
                    ),
                  ),
                ),
                
                // Accept Terms (for first time users)
                if (widget.isFirstTime) _buildAcceptTermsSection(),
              ],
            ),
          ),
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
            gradient: AppTheme.darkGradient,
          ),
          child: CustomPaint(
            painter: _PolicyBackgroundPainter(
              animationValue: _backgroundAnimationController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildFuturisticHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.6),
                  AppTheme.darkCard.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (!widget.isFirstTime)
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.darkCard.withOpacity(0.7),
                            AppTheme.darkCard.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppTheme.textWhite,
                        size: 20,
                      ),
                    ),
                  ),
                if (!widget.isFirstTime) const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => 
                            AppTheme.primaryGradient.createShader(bounds),
                        child: Text(
                          'سياسة الخصوصية',
                          style: AppTextStyles.heading2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'كيف نحمي معلوماتك',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (!widget.isFirstTime)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: _sharePrivacyPolicy,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.info.withOpacity(0.2),
            AppTheme.info.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.info, AppTheme.primaryBlue],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.update_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'آخر تحديث: يناير 2025',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyContent() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 100)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0).toDouble(),
                child: _buildPolicySection(section),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPolicySection(PolicySection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: section.gradient.colors[0].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              initiallyExpanded: section.isExpanded,
              tilePadding: const EdgeInsets.all(20),
              childrenPadding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20,
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: section.gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: section.gradient.colors[0].withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  section.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                section.title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Icon(
                Icons.expand_more_rounded,
                color: AppTheme.textMuted,
              ),
              children: [
                Text(
                  section.content.trim(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAcceptTermsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.darkCard.withOpacity(0.9),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _acceptTerms = !_acceptTerms;
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: _acceptTerms
                        ? AppTheme.primaryGradient
                        : null,
                    color: !_acceptTerms
                        ? AppTheme.darkCard.withOpacity(0.5)
                        : null,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _acceptTerms
                          ? Colors.transparent
                          : AppTheme.darkBorder.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: _acceptTerms
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'لقد قرأت وأوافق على سياسة الخصوصية والشروط والأحكام',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _acceptTerms
                  ? () {
                      context.read<SettingsBloc>().add(
                        const AcceptPrivacyPolicyEvent(),
                      );
                      context.go('/home');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _acceptTerms
                      ? AppTheme.primaryGradient
                      : LinearGradient(
                          colors: [
                            AppTheme.darkCard.withOpacity(0.5),
                            AppTheme.darkCard.withOpacity(0.3),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    'موافق ومتابعة',
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: _acceptTerms
                          ? Colors.white
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sharePrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('جاري مشاركة سياسة الخصوصية...'),
        backgroundColor: AppTheme.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Policy Section Model
class PolicySection {
  final String title;
  final IconData icon;
  final String content;
  final LinearGradient gradient;
  final bool isExpanded;

  PolicySection({
    required this.title,
    required this.icon,
    required this.content,
    required this.gradient,
    this.isExpanded = false,
  });
}

// Background Painter
class _PolicyBackgroundPainter extends CustomPainter {
  final double animationValue;
  
  _PolicyBackgroundPainter({required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Draw floating shapes
    for (int i = 0; i < 8; i++) {
      final offset = Offset(
        size.width * (0.1 + i * 0.15),
        size.height * (0.2 + math.sin(animationValue * 2 + i) * 0.1),
      );
      
      paint.shader = RadialGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: offset, radius: 80));
      
      canvas.drawCircle(offset, 80, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Add this event to settings_event.dart
class AcceptPrivacyPolicyEvent extends SettingsEvent {
  const AcceptPrivacyPolicyEvent();
}