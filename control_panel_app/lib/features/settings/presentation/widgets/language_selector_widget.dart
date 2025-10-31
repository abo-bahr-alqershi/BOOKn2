import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';

class FuturisticLanguageSelector extends StatefulWidget {
  final String currentLanguage;
  final Function(String)? onLanguageChanged;

  const FuturisticLanguageSelector({
    super.key,
    required this.currentLanguage,
    this.onLanguageChanged,
  });

  @override
  State<FuturisticLanguageSelector> createState() => 
      _FuturisticLanguageSelectorState();
}

class _FuturisticLanguageSelectorState extends State<FuturisticLanguageSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  final List<LanguageOption> _languages = [
    LanguageOption(
      code: 'ar',
      name: 'العربية',
      englishName: 'Arabic',
      flag: '🇾🇪',
      gradient: LinearGradient(
        colors: [AppTheme.primaryBlue, AppTheme.primaryCyan],
      ),
    ),
    LanguageOption(
      code: 'en',
      name: 'English',
      englishName: 'الإنجليزية',
      flag: '🇬🇧',
      gradient: LinearGradient(
        colors: [AppTheme.primaryPurple, AppTheme.primaryViolet],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = _languages.firstWhere(
      (lang) => lang.code == widget.currentLanguage,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: currentLang.gradient.colors[0].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current Language
              InkWell(
                onTap: _toggleExpanded,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Flag with Glow
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: currentLang.gradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: currentLang.gradient.colors[0]
                                  .withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            currentLang.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentLang.name,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currentLang.englishName,
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Language Options
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return SizeTransition(
                    sizeFactor: _scaleAnimation,
                    child: Column(
                      children: _languages
                          .where((lang) => lang.code != widget.currentLanguage)
                          .map((lang) => _buildLanguageOption(lang))
                          .toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(LanguageOption language) {
    return InkWell(
      onTap: () {
        _handleLanguageChange(language.code);
        _toggleExpanded();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.darkBorder.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Flag
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: language.gradient.scale(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  language.flag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textWhite,
                    ),
                  ),
                  Text(
                    language.englishName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
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

  void _handleLanguageChange(String languageCode) {
    if (widget.onLanguageChanged != null) {
      widget.onLanguageChanged!(languageCode);
    } else {
      context.read<SettingsBloc>().add(UpdateLanguageEvent(languageCode));
    }
    
    _showLanguageChangeSnackBar(languageCode);
  }

  void _showLanguageChangeSnackBar(String languageCode) {
    final language = _languages.firstWhere((lang) => lang.code == languageCode);
    
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
                  gradient: language.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    language.flag,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  languageCode == 'ar'
                      ? 'تم تغيير اللغة إلى العربية'
                      : 'Language changed to English',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.darkCard.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(20),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class LanguageOption {
  final String code;
  final String name;
  final String englishName;
  final String flag;
  final Gradient gradient;

  LanguageOption({
    required this.code,
    required this.name,
    required this.englishName,
    required this.flag,
    required this.gradient,
  });
}