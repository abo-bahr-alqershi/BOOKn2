import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/payment_method_enum.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../widgets/credit_card_form_widget.dart';

class AddPaymentMethodPage extends StatefulWidget {
  final PaymentMethod? initialMethod;

  const AddPaymentMethodPage({
    super.key,
    this.initialMethod,
  });

  @override
  State<AddPaymentMethodPage> createState() => _AddPaymentMethodPageState();
}

class _AddPaymentMethodPageState extends State<AddPaymentMethodPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _methodSelectorAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _particleAnimationController;
  
  // Animations
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _formSlideAnimation;
  late Animation<double> _glowAnimation;
  late List<Animation<double>> _methodAnimations;
  
  // Form and Data
  PaymentMethod _selectedMethod = PaymentMethod.creditCard;
  final _formKey = GlobalKey<FormState>();
  bool _saveCard = false;
  bool _isProcessing = false;
  
  // Particles
  final List<_FloatingOrb> _orbs = [];
  
  // Wallet Form Controllers (for Yemeni wallets)
  final _walletNumberController = TextEditingController();
  final _walletPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialMethod != null) {
      _selectedMethod = widget.initialMethod!;
    }
    _initializeAnimations();
    _generateOrbs();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Background Animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    // Card Animation
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _cardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
    
    // Form Animation
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _formSlideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    // Method Selector Animation
    _methodSelectorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _methodAnimations = List.generate(
      PaymentMethod.values.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _methodSelectorAnimationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutBack,
          ),
        ),
      ),
    );
    
    // Glow Animation
    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Particle Animation
    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }
  
  void _generateOrbs() {
    for (int i = 0; i < 5; i++) {
      _orbs.add(_FloatingOrb());
    }
  }
  
  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _cardAnimationController.forward();
      _methodSelectorAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _formAnimationController.forward();
      });
    });
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _cardAnimationController.dispose();
    _formAnimationController.dispose();
    _methodSelectorAnimationController.dispose();
    _glowAnimationController.dispose();
    _particleAnimationController.dispose();
    _walletNumberController.dispose();
    _walletPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentDetailsValid) {
            _savePaymentMethod();
          } else if (state is PaymentDetailsInvalid) {
            _showErrors(state.errors);
          }
        },
        child: Stack(
          children: [
            // Animated Background
            _buildAnimatedBackground(),
            
            // Floating Orbs
            _buildFloatingOrbs(),
            
            // Main Content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildFuturisticAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildMethodSelector(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _buildFormContent(),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
            
            // Processing Overlay
            if (_isProcessing) _buildProcessingOverlay(),
          ],
        ),
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
              begin: Alignment(
                math.sin(_backgroundAnimationController.value * 2 * math.pi),
                math.cos(_backgroundAnimationController.value * 2 * math.pi),
              ),
              end: Alignment(
                -math.sin(_backgroundAnimationController.value * 2 * math.pi),
                -math.cos(_backgroundAnimationController.value * 2 * math.pi),
              ),
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2,
                AppTheme.darkBackground3.withOpacity(0.8),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFloatingOrbs() {
    return AnimatedBuilder(
      animation: _particleAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _OrbPainter(
            orbs: _orbs,
            animationValue: _particleAnimationController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildFuturisticAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(
                              _glowAnimation.value * 0.5,
                            ),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_card,
                        size: 40,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    'إضافة طريقة دفع',
                    style: AppTextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      leading: _buildGlassBackButton(),
      actions: [
        _buildGlassActionButton(
          icon: Icons.help_outline,
          onPressed: _showHelp,
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
              onPressed: () => Navigator.pop(context),
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
  
  Widget _buildMethodSelector() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: PaymentMethod.values.length,
        itemBuilder: (context, index) {
          final method = PaymentMethod.values[index];
          final isSelected = method == _selectedMethod;
          
          return AnimatedBuilder(
            animation: _methodAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _methodAnimations[index].value,
                child: Opacity(
                  opacity: _methodAnimations[index].value,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedMethod = method;
                      });
                      _formAnimationController.reset();
                      _formAnimationController.forward();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  _getMethodColor(method),
                                  _getMethodColor(method).withOpacity(0.7),
                                ],
                              )
                            : null,
                        color: !isSelected
                            ? AppTheme.darkCard.withOpacity(0.5)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _getMethodColor(method)
                              : AppTheme.darkBorder.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _getMethodColor(method).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: isSelected ? 0 : 10,
                            sigmaY: isSelected ? 0 : 10,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getMethodIcon(method),
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textMuted,
                                size: 30,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                method.displayNameAr.split(' ').first,
                                style: AppTextStyles.caption.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textMuted,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildFormContent() {
    switch (_selectedMethod) {
      case PaymentMethod.creditCard:
        return _buildCreditCardForm();
      case PaymentMethod.jwaliWallet:
      case PaymentMethod.cashWallet:
      case PaymentMethod.oneCashWallet:
      case PaymentMethod.floskWallet:
      case PaymentMethod.jaibWallet:
        return _buildYemeniWalletForm();
      case PaymentMethod.paypal:
        return _buildPayPalForm();
      case PaymentMethod.cash:
        return _buildCashInfo();
    }
  }
  
  Widget _buildCreditCardForm() {
    return AnimatedBuilder(
      animation: _formSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _formSlideAnimation.value),
          child: FadeTransition(
            opacity: _cardFadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CreditCardFormWidget(
                      onCardNumberChanged: (value) {},
                      onCardHolderChanged: (value) {},
                      onExpiryDateChanged: (value) {},
                      onCvvChanged: (value) {},
                    ),
                    const SizedBox(height: 24),
                    _buildSaveCardOption(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildYemeniWalletForm() {
    return AnimatedBuilder(
      animation: _formSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _formSlideAnimation.value),
          child: FadeTransition(
            opacity: _cardFadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.6),
                    AppTheme.darkCard.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _getMethodColor(_selectedMethod).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Wallet Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                _getMethodColor(_selectedMethod).withOpacity(0.3),
                                _getMethodColor(_selectedMethod).withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getMethodIcon(_selectedMethod),
                            size: 50,
                            color: _getMethodColor(_selectedMethod),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              LinearGradient(
                                colors: [
                                  _getMethodColor(_selectedMethod),
                                  _getMethodColor(_selectedMethod).withOpacity(0.7),
                                ],
                              ).createShader(bounds),
                          child: Text(
                            _selectedMethod.displayNameAr,
                            style: AppTextStyles.heading2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          _getWalletDescription(_selectedMethod),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Wallet Number Field
                        _buildGlassTextField(
                          controller: _walletNumberController,
                          label: 'رقم المحفظة',
                          hint: _getWalletNumberHint(_selectedMethod),
                          icon: Icons.phone_android,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'رقم المحفظة مطلوب';
                            }
                            if (!_validateWalletNumber(value, _selectedMethod)) {
                              return 'رقم المحفظة غير صحيح';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // PIN Field
                        _buildGlassTextField(
                          controller: _walletPinController,
                          label: 'رمز التحقق (PIN)',
                          hint: 'أدخل رمز التحقق',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'رمز التحقق مطلوب';
                            }
                            if (value.length < 4) {
                              return 'رمز التحقق يجب أن يكون 4 أرقام على الأقل';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Security Note
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.info.withOpacity(0.1),
                                AppTheme.info.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.info.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.info,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'سيتم إرسال رمز تأكيد إلى رقم هاتفك المسجل',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        _buildSubmitButton(),
                      ],
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
  
  Widget _buildPayPalForm() {
    return AnimatedBuilder(
      animation: _formSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _formSlideAnimation.value),
          child: FadeTransition(
            opacity: _cardFadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.6),
                    AppTheme.darkCard.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF00457C).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00457C).withOpacity(0.3),
                              const Color(0xFF00457C).withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payment,
                          size: 60,
                          color: Color(0xFF00457C),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            const LinearGradient(
                              colors: [
                                Color(0xFF00457C),
                                Color(0xFF0070E0),
                              ],
                            ).createShader(bounds),
                        child: Text(
                          'PayPal',
                          style: AppTextStyles.displaySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'سيتم توجيهك إلى موقع PayPal',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppTheme.textWhite,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'قم بتسجيل الدخول إلى حساب PayPal الخاص بك لإكمال عملية الربط',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00457C),
                              Color(0xFF0070E0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00457C).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _connectPayPal,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.link,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ربط حساب PayPal',
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCashInfo() {
    return AnimatedBuilder(
      animation: _formSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _formSlideAnimation.value),
          child: FadeTransition(
            opacity: _cardFadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.success.withOpacity(0.1),
                    AppTheme.success.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.success.withOpacity(0.3),
                          AppTheme.success.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.money,
                      size: 60,
                      color: AppTheme.success,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        LinearGradient(
                          colors: [
                            AppTheme.success,
                            AppTheme.success.withOpacity(0.7),
                          ],
                        ).createShader(bounds),
                    child: Text(
                      'الدفع نقداً عند الوصول',
                      style: AppTextStyles.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'ستدفع المبلغ كاملاً عند تسجيل الوصول في العقار',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Features
                  _buildCashFeature(
                    icon: Icons.check_circle,
                    title: 'لا حاجة لبطاقة ائتمان',
                    description: 'ادفع نقداً مباشرة عند الوصول',
                  ),
                  const SizedBox(height: 16),
                  _buildCashFeature(
                    icon: Icons.security,
                    title: 'آمن وموثوق',
                    description: 'لا مشاركة لبيانات مالية',
                  ),
                  const SizedBox(height: 16),
                  _buildCashFeature(
                    icon: Icons.cancel,
                    title: 'إلغاء مجاني',
                    description: 'حتى 24 ساعة قبل الوصول',
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.success,
                          AppTheme.success.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.success.withOpacity(0.4),
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
                          Navigator.pop(context, PaymentMethod.cash);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Text(
                            'اختيار الدفع نقداً',
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
          ),
        );
      },
    );
  }
  
  Widget _buildCashFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.success.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
  
  Widget _buildGlassTextField({
    TextEditingController? controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
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
          child: TextFormField(
            controller: controller,
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
            validator: validator,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSaveCardOption() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.info.withOpacity(0.05),
            AppTheme.info.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: _saveCard ? AppTheme.primaryGradient : null,
              color: !_saveCard ? AppTheme.darkCard : null,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _saveCard
                    ? Colors.transparent
                    : AppTheme.darkBorder,
                width: 1,
              ),
            ),
            child: Checkbox(
              value: _saveCard,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _saveCard = value ?? false;
                });
              },
              fillColor: WidgetStateProperty.all(Colors.transparent),
              checkColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حفظ البطاقة للاستخدام المستقبلي',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: AppTheme.info,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'البيانات محمية ومشفرة بأعلى معايير الأمان',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
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
          onTap: _validateAndSave,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_card,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'إضافة طريقة الدفع',
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.95),
                AppTheme.darkCard.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  'جاري المعالجة...',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'يرجى الانتظار',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper Methods
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
  
  String _getWalletDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.jwaliWallet:
        return 'أدخل رقم محفظة جوالي المسجل لديك';
      case PaymentMethod.cashWallet:
        return 'أدخل رقم كاش محفظة الخاص بك';
      case PaymentMethod.oneCashWallet:
        return 'أدخل رقم محفظة ون كاش';
      case PaymentMethod.floskWallet:
        return 'أدخل رقم محفظة فلوس';
      case PaymentMethod.jaibWallet:
        return 'أدخل رقم محفظة جيب';
      default:
        return '';
    }
  }
  
  String _getWalletNumberHint(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.jwaliWallet:
        return '7XXXXXXXX';
      case PaymentMethod.cashWallet:
        return '7XXXXXXXX';
      case PaymentMethod.oneCashWallet:
        return '7XXXXXXXX';
      case PaymentMethod.floskWallet:
        return '7XXXXXXXX';
      case PaymentMethod.jaibWallet:
        return '7XXXXXXXX';
      default:
        return '';
    }
  }
  
  bool _validateWalletNumber(String number, PaymentMethod method) {
    // Validate Yemeni phone numbers (should start with 7 and be 9 digits)
    final cleanNumber = number.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid Yemeni mobile number
    if (cleanNumber.startsWith('967')) {
      return cleanNumber.length == 12 && cleanNumber[3] == '7';
    } else if (cleanNumber.startsWith('7')) {
      return cleanNumber.length == 9;
    }
    
    return false;
  }
  
  void _validateAndSave() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isProcessing = true;
      });
      
      // Simulate processing
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isProcessing = false;
        });
        
        context.read<PaymentBloc>().add(
          ValidatePaymentDetailsEvent(
            paymentMethod: _selectedMethod,
            // Add form field values here
          ),
        );
      });
    }
  }
  
  void _savePaymentMethod() {
    Navigator.pop(context, _selectedMethod);
    _showSuccessMessage();
  }
  
  void _showSuccessMessage() {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تمت العملية بنجاح',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'تمت إضافة طريقة الدفع بنجاح',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
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
  
  void _showErrors(Map<String, String> errors) {
    final errorMessage = errors.values.join('\n');
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
                      AppTheme.error.withOpacity(0.8),
                      AppTheme.error,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'خطأ في البيانات',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      errorMessage,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
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
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  void _connectPayPal() {
    // Implement PayPal connection
    setState(() {
      _isProcessing = true;
    });
    
    // Simulate PayPal OAuth flow
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isProcessing = false;
      });
      Navigator.pop(context, PaymentMethod.paypal);
      _showSuccessMessage();
    });
  }
  
  void _showHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildHelpModal(ctx),
    );
  }
  
  Widget _buildHelpModal(BuildContext ctx) {
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
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.help_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'المساعدة',
                            style: AppTextStyles.heading2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textWhite,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildHelpSection(
                        title: 'كيفية إضافة طريقة دفع',
                        items: [
                          'اختر طريقة الدفع المناسبة من القائمة',
                          'أدخل البيانات المطلوبة بدقة',
                          'تحقق من صحة البيانات المدخلة',
                          'اضغط على زر الإضافة لحفظ الطريقة',
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildHelpSection(
                        title: 'المحافظ اليمنية المدعومة',
                        items: [
                          'جوالي: للمدفوعات السريعة والآمنة',
                          'كاش: محفظة رقمية موثوقة',
                          'ون كاش: حلول دفع متقدمة',
                          'فلوس: محفظة إلكترونية سهلة',
                          'جيب: محفظة ذكية ومرنة',
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.info.withOpacity(0.1),
                              AppTheme.info.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.info.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: AppTheme.info,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ملاحظة أمنية',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.info,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'جميع البيانات محمية ومشفرة بأعلى معايير الأمان العالمية',
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHelpSection({
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textLight,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

// Floating Orb Model
class _FloatingOrb {
  late double x;
  late double y;
  late double radius;
  late double opacity;
  late Color color;
  late double speed;
  
  _FloatingOrb() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    radius = math.Random().nextDouble() * 50 + 20;
    opacity = math.Random().nextDouble() * 0.3 + 0.1;
    speed = math.Random().nextDouble() * 0.5 + 0.5;
    
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }
  
  void update(double animationValue) {
    y = (y + speed * 0.001) % 1.0;
    x = 0.5 + 0.3 * math.sin(animationValue * 2 * math.pi + y * math.pi);
  }
}

// Orb Painter
class _OrbPainter extends CustomPainter {
  final List<_FloatingOrb> orbs;
  final double animationValue;
  
  _OrbPainter({
    required this.orbs,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var orb in orbs) {
      orb.update(animationValue);
      
      final paint = Paint()
        ..color = orb.color.withOpacity(orb.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
      
      canvas.drawCircle(
        Offset(orb.x * size.width, orb.y * size.height),
        orb.radius,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}