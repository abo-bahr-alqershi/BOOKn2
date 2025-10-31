// lib/features/settings/presentation/pages/language_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _selectionController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _selectionAnimation;
  
  String? _selectedLanguage;
  
  final List<_UltraMinimalLanguage> _languages = [
    _UltraMinimalLanguage(
      code: 'ar',
      name: 'العربية',
      subtitle: 'Arabic',
      icon: '🇾🇪',
      direction: 'RTL',
    ),
    _UltraMinimalLanguage(
      code: 'en',
      name: 'English',
      subtitle: 'الإنجليزية',
      icon: '🇬🇧',
      direction: 'LTR',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentLanguage();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _selectionAnimation = CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeOutCubic,
    );
    
    _fadeController.forward();
    _slideController.forward();
  }
  
  void _loadCurrentLanguage() {
    final state = context.read<SettingsBloc>().state;
    if (state is SettingsLoaded || state is SettingsUpdated) {
      final settings = (state is SettingsLoaded) 
          ? state.settings 
          : (state as SettingsUpdated).settings;
      setState(() {
        _selectedLanguage = settings.preferredLanguage;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Ultra minimal gradient background
          _buildUltraMinimalBackground(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildUltraMinimalHeader(),
                Expanded(
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
          ),
        ],
      ),
    );
  }
  
  Widget _buildUltraMinimalBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkBackground.withBlue(AppTheme.darkBackground.blue + 4),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _UltraSubtleBackgroundPainter(
              pulseAnimation: _pulseAnimation.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
  
  Widget _buildUltraMinimalHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Back button
          _buildMinimalBackButton(),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اللغة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'اختر لغة التطبيق',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: AppTheme.textMuted.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          
          // Language icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.08),
                  AppTheme.primaryPurple.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.translate,
              color: AppTheme.primaryBlue.withOpacity(0.5),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMinimalBackButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.pop();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.05),
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          color: AppTheme.textWhite,
          size: 14,
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        String currentLanguage = 'ar';
        
        if (state is SettingsLoaded || state is SettingsUpdated) {
          final settings = (state is SettingsLoaded) 
              ? state.settings 
              : (state as SettingsUpdated).settings;
          currentLanguage = settings.preferredLanguage;
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 32),
              
              // Language cards
              ...List.generate(_languages.length, (index) {
                final language = _languages[index];
                final isSelected = language.code == currentLanguage;
                
                return TweenAnimationBuilder<double>(
                  key: ValueKey(language.code),
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 15 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _buildUltraMinimalLanguageCard(
                          language: language,
                          isSelected: isSelected,
                          onTap: () => _selectLanguage(language.code),
                        ),
                      ),
                    );
                  },
                );
              }),
              
              const SizedBox(height: 40),
              
              // Info section
              _buildInfoSection(currentLanguage),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildUltraMinimalLanguageCard({
    required _UltraMinimalLanguage language,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedLanguage = language.code;
        });
        if (isSelected) return;
        _selectionController.forward(from: 0);
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.05),
                    AppTheme.primaryPurple.withOpacity(0.02),
                  ],
                )
              : null,
          color: !isSelected 
              ? AppTheme.darkCard.withOpacity(0.03)
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.2)
                : AppTheme.darkBorder.withOpacity(0.05),
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Flag/Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 44 : 40,
              height: isSelected ? 44 : 40,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.1),
                          AppTheme.primaryPurple.withOpacity(0.05),
                        ],
                      )
                    : null,
                color: !isSelected
                    ? AppTheme.darkCard.withOpacity(0.05)
                    : null,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue.withOpacity(0.15)
                      : AppTheme.darkBorder.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  language.icon,
                  style: TextStyle(
                    fontSize: isSelected ? 22 : 20,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 14),
            
            // Language info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        language.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryBlue.withOpacity(0.9)
                              : AppTheme.textWhite.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue.withOpacity(0.1)
                              : AppTheme.darkCard.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          language.direction,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 9,
                            color: isSelected
                                ? AppTheme.primaryBlue.withOpacity(0.7)
                                : AppTheme.textMuted.withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    language.subtitle,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: AppTheme.textMuted.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 22 : 20,
              height: isSelected ? 22 : 20,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.8),
                          AppTheme.primaryPurple.withOpacity(0.6),
                        ],
                      )
                    : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppTheme.darkBorder.withOpacity(0.1),
                  width: isSelected ? 0 : 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoSection(String currentLanguage) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.info.withOpacity(0.03 * _pulseAnimation.value),
                AppTheme.info.withOpacity(0.01 * _pulseAnimation.value),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.info.withOpacity(0.08),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppTheme.info.withOpacity(0.6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentLanguage == 'ar' 
                          ? 'معلومة'
                          : 'Info',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.info.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentLanguage == 'ar'
                          ? 'سيتم تطبيق اللغة على جميع أجزاء التطبيق'
                          : 'Language will be applied to all app sections',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: AppTheme.textMuted.withOpacity(0.6),
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
  
  void _selectLanguage(String languageCode) {
    context.read<SettingsBloc>().add(UpdateLanguageEvent(languageCode));
    
    _showUltraMinimalSnackBar(languageCode);
  }
  
  void _showUltraMinimalSnackBar(String languageCode) {
    HapticFeedback.mediumImpact();
    
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _UltraMinimalSnackBar(
        languageCode: languageCode,
      ),
    );
    
    overlay.insert(overlayEntry);
    
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}

// Ultra Minimal Snackbar
class _UltraMinimalSnackBar extends StatefulWidget {
  final String languageCode;

  const _UltraMinimalSnackBar({
    required this.languageCode,
  });

  @override
  State<_UltraMinimalSnackBar> createState() => _UltraMinimalSnackBarState();
}

class _UltraMinimalSnackBarState extends State<_UltraMinimalSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _controller.forward();
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.languageCode == 'ar';
    
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.success.withOpacity(0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.success.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.success.withOpacity(0.2),
                              AppTheme.success.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: AppTheme.success.withOpacity(0.8),
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isArabic
                            ? 'تم تغيير اللغة إلى العربية'
                            : 'Language changed to English',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          color: AppTheme.textWhite.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Language Model
class _UltraMinimalLanguage {
  final String code;
  final String name;
  final String subtitle;
  final String icon;
  final String direction;

  const _UltraMinimalLanguage({
    required this.code,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.direction,
  });
}

// Ultra Subtle Background Painter
class _UltraSubtleBackgroundPainter extends CustomPainter {
  final double pulseAnimation;

  _UltraSubtleBackgroundPainter({
    required this.pulseAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    // Single subtle gradient orb
    final center = Offset(
      size.width * 0.8,
      size.height * 0.2,
    );
    
    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryBlue.withOpacity(0.02 * pulseAnimation),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: 200));
    
    canvas.drawCircle(center, 200, paint);
    
    // Second subtle orb
    final center2 = Offset(
      size.width * 0.2,
      size.height * 0.7,
    );
    
    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryPurple.withOpacity(0.01 * pulseAnimation),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: center2, radius: 150));
    
    canvas.drawCircle(center2, 150, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}