import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class CreditCardFormWidget extends StatefulWidget {
  final Function(String) onCardNumberChanged;
  final Function(String) onCardHolderChanged;
  final Function(String) onExpiryDateChanged;
  final Function(String) onCvvChanged;
  final bool showCardPreview;

  const CreditCardFormWidget({
    super.key,
    required this.onCardNumberChanged,
    required this.onCardHolderChanged,
    required this.onExpiryDateChanged,
    required this.onCvvChanged,
    this.showCardPreview = true,
  });

  @override
  State<CreditCardFormWidget> createState() => _CreditCardFormWidgetState();
}

class _CreditCardFormWidgetState extends State<CreditCardFormWidget>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _flipController;
  late AnimationController _glowController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;
  
  // Animations
  late Animation<double> _flipAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _shimmerAnimation;
  
  // Form Controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  
  // Focus Nodes
  final _cardNumberFocus = FocusNode();
  final _cardHolderFocus = FocusNode();
  final _expiryFocus = FocusNode();
  final _cvvFocus = FocusNode();
  
  // Card State
  bool _isCardFlipped = false;
  String _cardType = '';
  bool _isValidNumber = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupListeners();
  }

  void _initializeAnimations() {
    // Flip Animation
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
    
    // Glow Animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // Float Animation
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
    
    // Shimmer Animation
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(_shimmerController);
  }
  
  void _setupListeners() {
    // CVV Focus Listener for card flip
    _cvvFocus.addListener(() {
      if (_cvvFocus.hasFocus && !_isCardFlipped) {
        _flipCard();
      } else if (!_cvvFocus.hasFocus && _isCardFlipped) {
        _flipCard();
      }
    });
    
    // Card Number Listener for card type detection
    _cardNumberController.addListener(_detectCardType);
  }

  @override
  void dispose() {
    _flipController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNumberFocus.dispose();
    _cardHolderFocus.dispose();
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isCardFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isCardFlipped = !_isCardFlipped;
    });
    HapticFeedback.lightImpact();
  }

  void _detectCardType() {
    final number = _cardNumberController.text.replaceAll(' ', '');
    String type = '';
    bool isValid = false;
    
    if (number.startsWith('4')) {
      type = 'visa';
      isValid = number.length >= 13 && number.length <= 19;
    } else if (number.startsWith('5') || 
               (number.startsWith('2') && number.length >= 2 && 
                int.tryParse(number.substring(0, 2)) != null &&
                int.parse(number.substring(0, 2)) >= 22 && 
                int.parse(number.substring(0, 2)) <= 27)) {
      type = 'mastercard';
      isValid = number.length == 16;
    } else if ((number.startsWith('34') || number.startsWith('37'))) {
      type = 'amex';
      isValid = number.length == 15;
    } else if (number.startsWith('6')) {
      type = 'discover';
      isValid = number.length == 16;
    }
    
    if (type != _cardType || isValid != _isValidNumber) {
      setState(() {
        _cardType = type;
        _isValidNumber = isValid;
      });
      
      if (_isValidNumber) {
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showCardPreview) ...[
          _buildFuturisticCardPreview(),
          const SizedBox(height: 32),
        ],
        _buildFuturisticFormFields(),
      ],
    );
  }
  
  Widget _buildFuturisticCardPreview() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatAnimation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            height: 240,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final isShowingFront = _flipAnimation.value < 0.5;
                
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(_flipAnimation.value * math.pi),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _getCardGradient(),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _getCardColor().withOpacity(
                            0.3 * _glowAnimation.value,
                          ),
                          blurRadius: 30,
                          spreadRadius: 10,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Shimmer Effect
                          if (!_isCardFlipped)
                            AnimatedBuilder(
                              animation: _shimmerAnimation,
                              builder: (context, child) {
                                return Positioned.fill(
                                  child: CustomPaint(
                                    painter: _ShimmerPainter(
                                      shimmerPosition: _shimmerAnimation.value,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                );
                              },
                            ),
                          
                          // Card Content
                          isShowingFront
                              ? _buildCardFront()
                              : Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(math.pi),
                                  child: _buildCardBack(),
                                ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCardFront() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardTypeIcon(),
              _buildCardChip(),
            ],
          ),
          
          // Card Number
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CARD NUMBER',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCardNumber(_cardNumberController.text),
                style: AppTextStyles.heading1.copyWith(
                  color: Colors.white,
                  letterSpacing: 3,
                  fontFamily: 'monospace',
                  fontSize: 22,
                ),
              ),
            ],
          ),
          
          // Bottom Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Card Holder
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARD HOLDER',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cardHolderController.text.isEmpty
                          ? 'YOUR NAME'
                          : _cardHolderController.text.toUpperCase(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Expiry Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPIRES',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _expiryController.text.isEmpty
                        ? 'MM/YY'
                        : _expiryController.text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCardBack() {
    return Column(
      children: [
        // Magnetic Strip
        Container(
          height: 50,
          margin: const EdgeInsets.only(top: 30),
          color: Colors.black87,
        ),
        
        const SizedBox(height: 20),
        
        // Signature and CVV
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Signature Strip
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'AUTHORIZED SIGNATURE',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.black54,
                      fontSize: 8,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // CVV
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _cvvController.text.isEmpty 
                          ? 'CVV' 
                          : _cvvController.text.padRight(3, '•'),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Security Text
              Text(
                'This card is property of the issuing bank',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCardTypeIcon() {
    if (_cardType.isEmpty) {
      return Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCardIcon(),
            size: 24,
            color: _getCardIconColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _cardType.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: _getCardIconColor(),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCardChip() {
    return Container(
      width: 50,
      height: 35,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.yellow.shade700,
            Colors.yellow.shade600,
            Colors.yellow.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ChipPainter(),
      ),
    );
  }
  
  Widget _buildFuturisticFormFields() {
    return Container(
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
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              // Card Number Field
              _buildFuturisticField(
                controller: _cardNumberController,
                focusNode: _cardNumberFocus,
                label: 'رقم البطاقة',
                hint: '0000 0000 0000 0000',
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CardNumberFormatter(),
                  LengthLimitingTextInputFormatter(19),
                ],
                suffixWidget: _isValidNumber
                    ? Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.success,
                              AppTheme.success.withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      )
                    : null,
                onChanged: (value) {
                  widget.onCardNumberChanged(value.replaceAll(' ', ''));
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'رقم البطاقة مطلوب';
                  }
                  if (!_isValidNumber) {
                    return 'رقم البطاقة غير صحيح';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Card Holder Name Field
              _buildFuturisticField(
                controller: _cardHolderController,
                focusNode: _cardHolderFocus,
                label: 'اسم حامل البطاقة',
                hint: 'الاسم كما هو مكتوب على البطاقة',
                icon: Icons.person_outline,
                textCapitalization: TextCapitalization.characters,
                onChanged: widget.onCardHolderChanged,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'اسم حامل البطاقة مطلوب';
                  }
                  if (value.length < 3) {
                    return 'الاسم قصير جداً';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Expiry Date and CVV Row
              Row(
                children: [
                  Expanded(
                    child: _buildFuturisticField(
                      controller: _expiryController,
                      focusNode: _expiryFocus,
                      label: 'تاريخ الانتهاء',
                      hint: 'MM/YY',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ExpiryDateFormatter(),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      onChanged: widget.onExpiryDateChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'التاريخ مطلوب';
                        }
                        if (value.length < 5) {
                          return 'تاريخ غير صالح';
                        }
                        
                        // Validate expiry date
                        final parts = value.split('/');
                        if (parts.length == 2) {
                          final month = int.tryParse(parts[0]);
                          final year = int.tryParse(parts[1]);
                          
                          if (month == null || month < 1 || month > 12) {
                            return 'شهر غير صالح';
                          }
                          
                          final currentYear = DateTime.now().year % 100;
                          final currentMonth = DateTime.now().month;
                          
                          if (year != null) {
                            if (year < currentYear || 
                                (year == currentYear && month < currentMonth)) {
                              return 'البطاقة منتهية';
                            }
                          }
                        }
                        
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: _buildFuturisticField(
                      controller: _cvvController,
                      focusNode: _cvvFocus,
                      label: 'CVV',
                      hint: _cardType == 'amex' ? '0000' : '000',
                      icon: Icons.lock_outline,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          _cardType == 'amex' ? 4 : 3,
                        ),
                      ],
                      onChanged: widget.onCvvChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'CVV مطلوب';
                        }
                        final requiredLength = _cardType == 'amex' ? 4 : 3;
                        if (value.length < requiredLength) {
                          return 'CVV غير صالح';
                        }
                        return null;
                      },
                      helperText: 'الرقم خلف البطاقة',
                    ),
                  ),
                ],
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.info,
                            AppTheme.info.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'معلوماتك آمنة',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.info,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'جميع المعلومات مشفرة ومحمية بتقنية SSL 256-bit',
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
    );
  }
  
  Widget _buildFuturisticField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixWidget,
    String? helperText,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppTheme.textWhite,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: focusNode.hasFocus 
              ? AppTheme.primaryBlue 
              : AppTheme.textMuted,
        ),
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color: AppTheme.textMuted.withOpacity(0.5),
        ),
        helperStyle: AppTextStyles.caption.copyWith(
          color: AppTheme.textMuted.withOpacity(0.7),
        ),
        prefixIcon: Icon(
          icon,
          color: focusNode.hasFocus 
              ? AppTheme.primaryBlue 
              : AppTheme.textMuted,
        ),
        suffixIcon: suffixWidget,
        filled: true,
        fillColor: AppTheme.darkCard.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.primaryBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.error,
            width: 2,
          ),
        ),
      ),
    );
  }
  
  LinearGradient _getCardGradient() {
    switch (_cardType) {
      case 'visa':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1F71),
            Color(0xFF115DD8),
          ],
        );
      case 'mastercard':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEB001B),
            Color(0xFFF79E1B),
          ],
        );
      case 'amex':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF006FCF),
            Color(0xFF0088CC),
          ],
        );
      case 'discover':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6600),
            Color(0xFFFF9933),
          ],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryPurple,
            AppTheme.primaryViolet,
          ],
        );
    }
  }
  
  Color _getCardColor() {
    switch (_cardType) {
      case 'visa':
        return const Color(0xFF115DD8);
      case 'mastercard':
        return const Color(0xFFEB001B);
      case 'amex':
        return const Color(0xFF006FCF);
      case 'discover':
        return const Color(0xFFFF6600);
      default:
        return AppTheme.primaryBlue;
    }
  }
  
  IconData _getCardIcon() {
    switch (_cardType) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      case 'discover':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }
  
  Color _getCardIconColor() {
    switch (_cardType) {
      case 'visa':
        return const Color(0xFF115DD8);
      case 'mastercard':
        return const Color(0xFFEB001B);
      case 'amex':
        return const Color(0xFF006FCF);
      case 'discover':
        return const Color(0xFFFF6600);
      default:
        return AppTheme.primaryBlue;
    }
  }
  
  String _formatCardNumber(String number) {
    final cleaned = number.replaceAll(' ', '');
    if (cleaned.isEmpty) return '•••• •••• •••• ••••';
    
    final formatted = StringBuffer();
    final spacing = _cardType == 'amex' ? [4, 6, 5] : [4, 4, 4, 4];
    int index = 0;
    
    for (int groupSize in spacing) {
      if (index >= cleaned.length) break;
      
      if (formatted.isNotEmpty) {
        formatted.write(' ');
      }
      
      final end = (index + groupSize).clamp(0, cleaned.length);
      formatted.write(cleaned.substring(index, end));
      index = end;
    }
    
    // Fill remaining with dots
    final totalDigits = _cardType == 'amex' ? 15 : 16;
    final remaining = totalDigits - cleaned.length;
    
    if (remaining > 0) {
      if (formatted.isNotEmpty && cleaned.isNotEmpty) {
        formatted.write(' ');
      }
      
      for (int i = 0; i < remaining; i++) {
        if (i > 0 && i % 4 == 0 && _cardType != 'amex') {
          formatted.write(' ');
        }
        formatted.write('•');
      }
    }
    
    return formatted.toString();
  }
}

// Custom Input Formatters
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Shimmer Painter
class _ShimmerPainter extends CustomPainter {
  final double shimmerPosition;
  final Color color;
  
  _ShimmerPainter({
    required this.shimmerPosition,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment(-1.0 + shimmerPosition * 2, -1.0 + shimmerPosition * 2),
      end: Alignment(-0.3 + shimmerPosition * 2, -0.3 + shimmerPosition * 2),
      colors: [
        Colors.transparent,
        color,
        color,
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(rect, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Chip Painter
class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.shade700.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Draw chip circuits
    const lineSpacing = 4.0;
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint..strokeWidth = 0.5,
      );
    }
    
    for (double x = lineSpacing; x < size.width; x += lineSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint..strokeWidth = 0.5,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}