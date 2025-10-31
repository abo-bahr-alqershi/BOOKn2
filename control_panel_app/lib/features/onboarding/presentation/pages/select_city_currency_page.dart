// lib/features/onboarding/presentation/pages/select_city_currency_page.dart

import 'package:bookn_cp_app/features/reference/domain/entities/city.dart';
import 'package:bookn_cp_app/features/reference/domain/entities/currency.dart';
import 'package:bookn_cp_app/features/reference/presentation/bloc/reference_bloc.dart';
import 'package:bookn_cp_app/features/reference/presentation/bloc/reference_event.dart';
import 'package:bookn_cp_app/features/reference/presentation/bloc/reference_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

class SelectCityCurrencyPage extends StatefulWidget {
  const SelectCityCurrencyPage({super.key});

  @override
  State<SelectCityCurrencyPage> createState() => _SelectCityCurrencyPageState();
}

class _SelectCityCurrencyPageState extends State<SelectCityCurrencyPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late AnimationController _waveController;
  late AnimationController _buttonAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _buttonScaleAnimation;

  // State
  String? _selectedCity;
  String? _selectedCurrency;
  final _searchCityController = TextEditingController();
  final _searchCurrencyController = TextEditingController();
  String _citySearchQuery = '';
  String _currencySearchQuery = '';
  int _currentStep = 0; // 0: city, 1: currency
  bool _isButtonPressed = false;

  // Particles
  final List<_FloatingParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _startAnimations();

    // Load reference data
    context.read<ReferenceBloc>().add(const LoadReferenceDataEvent());
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
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

    _waveAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(_FloatingParticle());
    }
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _contentAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _contentAnimationController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _waveController.dispose();
    _buttonAnimationController.dispose();
    _searchCityController.dispose();
    _searchCurrencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: BlocListener<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingCompleted) {
            HapticFeedback.mediumImpact();
            context.go('/register', extra: {"isFirst": true});
          }
        },
        child: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(),

            // Floating particles
            _buildFloatingParticles(),

            // Main content
            _buildMainContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _waveAnimation]),
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
          child: Stack(
            children: [
              // Wave pattern
              CustomPaint(
                painter: _WavePatternPainter(
                  animation: _waveAnimation.value,
                  color: AppTheme.primaryBlue.withOpacity(0.03),
                ),
                size: Size.infinite,
              ),

              // Grid overlay
              CustomPaint(
                painter: _GridPatternPainter(
                  rotation: _rotationAnimation.value * 0.1,
                  opacity: 0.02,
                ),
                size: Size.infinite,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            animationValue: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: BlocBuilder<ReferenceBloc, ReferenceState>(
              builder: (context, state) {
                if (state is ReferenceLoading) {
                  return _buildLoadingState();
                }

                if (state is ReferenceError) {
                  return _buildErrorState(state.message);
                }

                if (state is ReferenceDataLoaded) {
                  return _buildContentLayout(state);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom loading indicator
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(
                        0.3 + 0.2 * _glowAnimation.value,
                      ),
                      blurRadius: 20 + 10 * _glowAnimation.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'جاري التحضير...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error.withOpacity(0.2),
                    AppTheme.error.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppTheme.error.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حدث خطأ',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildRetryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<ReferenceBloc>().add(const LoadReferenceDataEvent());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.refresh_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'إعادة المحاولة',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentLayout(ReferenceDataLoaded state) {
    return Column(
      children: [
        // Compact header
        _buildCompactHeader(),

        // Progress indicator
        _buildProgressIndicator(),

        // Content area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _currentStep == 0
                  ? _buildCitySelection(state.cities)
                  : _buildCurrencySelection(state.currencies),
            ),
          ),
        ),

        // Bottom action area
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // Logo with glow
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(
                        0.3 + 0.1 * _glowAnimation.value,
                      ),
                      blurRadius: 12 + 4 * _glowAnimation.value,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    _currentStep == 0 ? 'اختر مدينتك' : 'اختر العملة',
                    style: AppTextStyles.heading3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  _currentStep == 0
                      ? 'حدد موقعك للحصول على أفضل العروض'
                      : 'اختر العملة المفضلة للعرض',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Skip button (optional)
          if (_currentStep == 0)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _currentStep = 1;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.darkBorder.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'تخطي',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Step 1
          Expanded(
            child: _buildStepIndicator(
              isActive: true,
              isCompleted: _currentStep > 0,
              label: 'المدينة',
            ),
          ),

          // Connector
          Container(
            width: 24,
            height: 1,
            color: _currentStep > 0
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.2),
          ),

          // Step 2
          Expanded(
            child: _buildStepIndicator(
              isActive: _currentStep == 1,
              isCompleted: false,
              label: 'العملة',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required bool isActive,
    required bool isCompleted,
    required String label,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 3,
          decoration: BoxDecoration(
            gradient: isActive || isCompleted ? AppTheme.primaryGradient : null,
            color: !isActive && !isCompleted
                ? AppTheme.darkBorder.withOpacity(0.2)
                : null,
            borderRadius: BorderRadius.circular(2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isActive
                ? AppTheme.primaryBlue
                : AppTheme.textMuted.withOpacity(0.5),
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCitySelection(List<City> cities) {
    final filteredCities = _citySearchQuery.isEmpty
        ? cities
        : cities
            .where((city) =>
                city.name
                    .toLowerCase()
                    .contains(_citySearchQuery.toLowerCase()) ||
                city.country
                    .toLowerCase()
                    .contains(_citySearchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        // Search field
        _buildSearchField(
          controller: _searchCityController,
          hint: 'ابحث عن مدينة...',
          onChanged: (value) {
            setState(() {
              _citySearchQuery = value;
            });
          },
        ),

        const SizedBox(height: 16),

        // Cities grid
        Expanded(
          child: filteredCities.isEmpty
              ? _buildEmptySearchState()
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredCities.length,
                  itemBuilder: (context, index) {
                    final city = filteredCities[index];
                    final isSelected = city.name == _selectedCity;

                    return _CompactCityCard(
                      city: city,
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedCity = city.name;
                        });
                      },
                      animationDelay: Duration(milliseconds: index * 30),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCurrencySelection(List<Currency> currencies) {
    final filteredCurrencies = _currencySearchQuery.isEmpty
        ? currencies
        : currencies
            .where((currency) =>
                currency.code
                    .toLowerCase()
                    .contains(_currencySearchQuery.toLowerCase()) ||
                currency.arabicName
                    .toLowerCase()
                    .contains(_currencySearchQuery.toLowerCase()) ||
                currency.name
                    .toLowerCase()
                    .contains(_currencySearchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        // Search field
        _buildSearchField(
          controller: _searchCurrencyController,
          hint: 'ابحث عن عملة...',
          onChanged: (value) {
            setState(() {
              _currencySearchQuery = value;
            });
          },
        ),

        const SizedBox(height: 16),

        // Currencies list
        Expanded(
          child: filteredCurrencies.isEmpty
              ? _buildEmptySearchState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filteredCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = filteredCurrencies[index];
                    final isSelected = currency.code == _selectedCurrency;

                    return _CompactCurrencyCard(
                      currency: currency,
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedCurrency = currency.code;
                        });
                      },
                      animationDelay: Duration(milliseconds: index * 30),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: controller,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textWhite,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
                fontSize: 12,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppTheme.primaryBlue.withOpacity(0.5),
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppTheme.textMuted.withOpacity(0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد نتائج',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          Text(
            'جرب البحث بكلمات أخرى',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withOpacity(0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final canProceed = _currentStep == 0
        ? _selectedCity != null
        : _selectedCity != null && _selectedCurrency != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkBackground.withOpacity(0),
            AppTheme.darkBackground.withOpacity(0.9),
            AppTheme.darkBackground,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back button (if on step 2)
            if (_currentStep == 1) ...[
              _buildSecondaryButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  setState(() {
                    _currentStep = 0;
                  });
                },
              ),
              const SizedBox(width: 12),
            ],

            // Main action button
            Expanded(
              child: _buildPrimaryButton(
                enabled: canProceed,
                onTap: () {
                  if (_currentStep == 0) {
                    setState(() {
                      _currentStep = 1;
                    });
                  } else {
                    context.read<OnboardingBloc>().add(
                          CompleteOnboardingEvent(
                            city: _selectedCity!,
                            currencyCode: _selectedCurrency!,
                          ),
                        );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          color: AppTheme.textWhite,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: enabled
          ? (_) {
              setState(() => _isButtonPressed = true);
              _buttonAnimationController.forward();
            }
          : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isButtonPressed = false);
              _buttonAnimationController.reverse();
            }
          : null,
      onTapCancel: enabled
          ? () {
              setState(() => _isButtonPressed = false);
              _buttonAnimationController.reverse();
            }
          : null,
      onTap: enabled
          ? () {
              HapticFeedback.mediumImpact();
              onTap();
            }
          : null,
      child: AnimatedBuilder(
        animation: _buttonScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isButtonPressed ? _buttonScaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                gradient: enabled
                    ? AppTheme.primaryGradient
                    : LinearGradient(
                        colors: [
                          AppTheme.darkCard.withOpacity(0.3),
                          AppTheme.darkCard.withOpacity(0.2),
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: enabled
                      ? AppTheme.primaryBlue.withOpacity(0.3)
                      : AppTheme.darkBorder.withOpacity(0.1),
                  width: 0.5,
                ),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == 0 ? 'التالي' : 'ابدأ الآن',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: enabled
                            ? Colors.white
                            : AppTheme.textMuted.withOpacity(0.3),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentStep == 0
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                      color: enabled
                          ? Colors.white
                          : AppTheme.textMuted.withOpacity(0.3),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Compact City Card Widget
class _CompactCityCard extends StatefulWidget {
  final City city;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDelay;

  const _CompactCityCard({
    required this.city,
    required this.isSelected,
    required this.onTap,
    required this.animationDelay,
  });

  @override
  State<_CompactCityCard> createState() => _CompactCityCardState();
}

class _CompactCityCardState extends State<_CompactCityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _controller.forward();
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? AppTheme.primaryGradient
                : LinearGradient(
                    colors: [
                      AppTheme.darkCard.withOpacity(0.5),
                      AppTheme.darkCard.withOpacity(0.3),
                    ],
                  ),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.primaryBlue.withOpacity(0.5)
                  : AppTheme.darkBorder.withOpacity(0.15),
              width: widget.isSelected ? 1 : 0.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: widget.isSelected
                            ? const LinearGradient(
                                colors: [Colors.white24, Colors.white12],
                              )
                            : null,
                        color: !widget.isSelected
                            ? AppTheme.primaryBlue.withOpacity(0.15)
                            : null,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: widget.isSelected
                            ? Colors.white
                            : AppTheme.primaryBlue.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.city.name,
                            style: AppTextStyles.caption.copyWith(
                              color: widget.isSelected
                                  ? Colors.white
                                  : AppTheme.textWhite.withOpacity(0.9),
                              fontWeight: widget.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.city.country,
                            style: AppTextStyles.caption.copyWith(
                              color: widget.isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : AppTheme.textMuted.withOpacity(0.5),
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.isSelected)
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 10,
                          color: AppTheme.primaryBlue,
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
}

// Compact Currency Card Widget
class _CompactCurrencyCard extends StatefulWidget {
  final Currency currency;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDelay;

  const _CompactCurrencyCard({
    required this.currency,
    required this.isSelected,
    required this.onTap,
    required this.animationDelay,
  });

  @override
  State<_CompactCurrencyCard> createState() => _CompactCurrencyCardState();
}

class _CompactCurrencyCardState extends State<_CompactCurrencyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _controller.forward();
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
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _controller.value,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                      ? AppTheme.primaryGradient
                      : LinearGradient(
                          colors: [
                            AppTheme.darkCard.withOpacity(0.5),
                            AppTheme.darkCard.withOpacity(0.3),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.15),
                    width: widget.isSelected ? 1 : 0.5,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: widget.isSelected
                                  ? const LinearGradient(
                                      colors: [Colors.white24, Colors.white12],
                                    )
                                  : null,
                              color: !widget.isSelected
                                  ? AppTheme.primaryPurple.withOpacity(0.15)
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                widget.currency.arabicCode,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: widget.isSelected
                                      ? Colors.white
                                      : AppTheme.primaryPurple.withOpacity(0.7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.currency.code,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: widget.isSelected
                                            ? Colors.white
                                            : AppTheme.textWhite
                                                .withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.isSelected
                                            ? Colors.white.withOpacity(0.15)
                                            : AppTheme.darkBorder
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        widget.currency.name,
                                        style: AppTextStyles.caption.copyWith(
                                          color: widget.isSelected
                                              ? Colors.white.withOpacity(0.9)
                                              : AppTheme.textMuted
                                                  .withOpacity(0.5),
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.currency.arabicName,
                                  style: AppTextStyles.caption.copyWith(
                                    color: widget.isSelected
                                        ? Colors.white.withOpacity(0.8)
                                        : AppTheme.textMuted.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.isSelected)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: AppTheme.primaryBlue,
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
      },
    );
  }
}

// Floating Particle Model
class _FloatingParticle {
  late double x, y;
  late double vx, vy;
  late double radius;
  late double opacity;
  late Color color;

  _FloatingParticle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.0005;
    vy = (math.Random().nextDouble() - 0.5) * 0.0005;
    radius = math.Random().nextDouble() * 1.5 + 0.5;
    opacity = math.Random().nextDouble() * 0.2 + 0.05;

    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
      AppTheme.primaryViolet,
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

// Custom Painters
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
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

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

class _WavePatternPainter extends CustomPainter {
  final double animation;
  final Color color;

  _WavePatternPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 5) {
      final y = size.height * 0.9 +
          math.sin((x / size.width * 3 * math.pi) + (animation * 2 * math.pi)) *
              20;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GridPatternPainter extends CustomPainter {
  final double rotation;
  final double opacity;

  _GridPatternPainter({
    required this.rotation,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation);
    canvas.translate(-size.width / 2, -size.height / 2);

    const spacing = 25.0;

    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, -size.height),
        Offset(x, size.height * 2),
        paint,
      );
    }

    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      canvas.drawLine(
        Offset(-size.width, y),
        Offset(size.width * 2, y),
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
