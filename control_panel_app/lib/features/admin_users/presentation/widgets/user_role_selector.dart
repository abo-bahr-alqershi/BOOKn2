// lib/features/admin_users/presentation/widgets/user_role_selector.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';

class UserRoleSelector extends StatefulWidget {
  final String? currentRole;
  final Function(String) onRoleSelected;

  const UserRoleSelector({
    super.key,
    this.currentRole,
    required this.onRoleSelected,
  });

  @override
  State<UserRoleSelector> createState() => _UserRoleSelectorState();
}

class _UserRoleSelectorState extends State<UserRoleSelector>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _glowController;
  late AnimationController _slideController;
  
  // Animations
  late Animation<double> _backgroundRotation;
  late Animation<double> _glowAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // State
  String? _selectedRole;
  
  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'admin',
      'name': 'مدير',
      'description': 'صلاحيات كاملة على النظام',
      'icon': Icons.admin_panel_settings_rounded,
      'gradient': [AppTheme.error, AppTheme.primaryViolet],
      'features': ['إدارة كاملة', 'تقارير متقدمة', 'إعدادات النظام'],
    },
    {
      'id': 'owner',
      'name': 'مالك',
      'description': 'مالك كيان أو عقار',
      'icon': Icons.business_rounded,
      'gradient': [AppTheme.primaryBlue, AppTheme.primaryPurple],
      'features': ['إدارة العقارات', 'تقارير الأرباح', 'إدارة الموظفين'],
    },
    {
      'id': 'client',
      'name': 'عميل',
      'description': 'مستخدم عادي للخدمة',
      'icon': Icons.person_rounded,
      'gradient': [AppTheme.primaryCyan, AppTheme.neonGreen],
      'features': ['حجز الخدمات', 'عرض السجل', 'التقييمات'],
    },
    {
      'id': 'staff',
      'name': 'موظف',
      'description': 'موظف في كيان أو عقار',
      'icon': Icons.badge_rounded,
      'gradient': [AppTheme.warning, AppTheme.neonBlue],
      'features': ['إدارة الحجوزات', 'خدمة العملاء', 'التقارير الأساسية'],
    },
    {
      'id': 'guest',
      'name': 'ضيف',
      'description': 'مستخدم بدون تسجيل',
      'icon': Icons.hail_rounded,
      'gradient': [AppTheme.primaryPurple, AppTheme.primaryCyan],
      'features': ['تصفح', 'اكتشاف العروض'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _backgroundRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.linear,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeIn,
    );
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _glowController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkCard.withOpacity(0.95),
                AppTheme.darkCard.withOpacity(0.85),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Stack(
                children: [
                  // Animated Background
                  _buildAnimatedBackground(),
                  
                  // Content
                  Column(
                    children: [
                      _buildHandle(),
                      _buildHeader(),
                      Expanded(
                        child: _buildRolesList(),
                      ),
                      _buildActions(),
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
  
  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _backgroundRotation,
        builder: (context, child) {
          return CustomPaint(
            painter: _SelectorBackgroundPainter(
              rotation: _backgroundRotation.value,
              glowIntensity: _glowAnimation.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.4 * _glowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    'اختر دور المستخدم',
                    style: AppTextStyles.heading3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'حدد الصلاحيات المناسبة للمستخدم',
                  style: AppTextStyles.caption.copyWith(
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

  Widget _buildRolesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: _roles.length,
      itemBuilder: (context, index) {
        final role = _roles[index];
        final isSelected = _selectedRole == role['id'];
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            final double clampedOpacity = value.clamp(0.0, 1.0) as double;
            final double clampedScale = value < 0 ? 0 : value; // allow overshoot >1 for scale
            return Transform.scale(
              scale: clampedScale,
              child: Opacity(
                opacity: clampedOpacity,
                child: _buildRoleCard(role, isSelected),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedRole = role['id'];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    (role['gradient'] as List<Color>)[0].withOpacity(0.2),
                    (role['gradient'] as List<Color>)[1].withOpacity(0.1),
                  ]
                : [
                    AppTheme.darkCard.withOpacity(0.5),
                    AppTheme.darkCard.withOpacity(0.3),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (role['gradient'] as List<Color>)[0].withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (role['gradient'] as List<Color>)[0].withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: role['gradient'] as List<Color>,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: (role['gradient'] as List<Color>)[0].withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          role['icon'] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Title & Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role['name'] as String,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              role['description'] as String,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Selection Indicator
                      if (isSelected)
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: role['gradient'] as List<Color>,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (role['gradient'] as List<Color>)[0].withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  
                  // Features
                  if (isSelected) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBackground.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: (role['gradient'] as List<Color>)[0],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: (role['features'] as List<String>).map((feature) {
                                return Chip(
                                  label: Text(
                                    feature,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.textWhite,
                                      fontSize: 10,
                                    ),
                                  ),
                                  backgroundColor: (role['gradient'] as List<Color>)[0].withOpacity(0.2),
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.darkSurface.withOpacity(0.5),
                      AppTheme.darkSurface.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                ),
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
          
          const SizedBox(width: 12),
          
          // Confirm Button
          Expanded(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return GestureDetector(
                  onTap: _selectedRole != null
                      ? () {
                          HapticFeedback.mediumImpact();
                          widget.onRoleSelected(_selectedRole!);
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: AnimatedOpacity(
                    opacity: _selectedRole != null ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _selectedRole != null
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(
                                    0.3 + 0.2 * _glowAnimation.value,
                                  ),
                                  blurRadius: 12 + 8 * _glowAnimation.value,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'تأكيد',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Background Painter
class _SelectorBackgroundPainter extends CustomPainter {
  final double rotation;
  final double glowIntensity;
  
  _SelectorBackgroundPainter({
    required this.rotation,
    required this.glowIntensity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Draw animated circles
    paint.color = AppTheme.primaryBlue.withOpacity(0.02 * glowIntensity);
    
    for (int i = 0; i < 3; i++) {
      final radius = 100.0 + i * 50;
      final center = Offset(
        size.width / 2 + math.cos(rotation + i) * 30,
        size.height / 2 + math.sin(rotation + i) * 30,
      );
      
      canvas.drawCircle(center, radius, paint);
    }
    
    // Draw decorative lines
    paint.color = AppTheme.primaryBlue.withOpacity(0.01);
    const lineCount = 5;
    
    for (int i = 0; i < lineCount; i++) {
      final y = size.height * (i + 1) / (lineCount + 1);
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