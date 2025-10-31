import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class OtpInputWidget extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  
  const OtpInputWidget({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget>
    with TickerProviderStateMixin {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(),
    );
    _animationControllers = List.generate(
      widget.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.1,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();
    
    // Add focus listeners
    for (int i = 0; i < widget.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          _animationControllers[i].forward();
        } else {
          _animationControllers[i].reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Animate current field
      _animationControllers[index].forward().then((_) {
        _animationControllers[index].reverse();
      });
      
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Unfocus when last field is filled
        _focusNodes[index].unfocus();
      }
    }

    String otp = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(otp);

    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }

  void _onKeyDown(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            widget.length,
            (index) => _buildOtpField(index),
          ),
        ),
        const SizedBox(height: 30),
        _buildResendSection(),
      ],
    );
  }
  
  Widget _buildOtpField(int index) {
    final isFilled = _controllers[index].text.isNotEmpty;
    
    return AnimatedBuilder(
      animation: _scaleAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimations[index].value,
          child: Container(
            width: 50,
            height: 60,
            decoration: BoxDecoration(
              gradient: isFilled
                  ? AppTheme.primaryGradient
                  : LinearGradient(
                      colors: [
                        AppTheme.darkCard.withOpacity(0.5),
                        AppTheme.darkCard.withOpacity(0.3),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focusNodes[index].hasFocus
                    ? AppTheme.primaryBlue
                    : AppTheme.darkBorder.withOpacity(0.3),
                width: _focusNodes[index].hasFocus ? 2 : 1,
              ),
              boxShadow: _focusNodes[index].hasFocus
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) => _onKeyDown(event, index),
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    onChanged: (value) => _onChanged(value, index),
                    style: AppTextStyles.heading2.copyWith(
                      color: isFilled ? Colors.white : AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
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
  
  Widget _buildResendSection() {
    return TweenAnimationBuilder<Duration>(
      duration: const Duration(seconds: 60),
      tween: Tween(
        begin: const Duration(seconds: 60),
        end: Duration.zero,
      ),
      builder: (context, value, child) {
        final seconds = value.inSeconds;
        final canResend = seconds == 0;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              canResend
                  ? 'لم تستلم الرمز؟'
                  : 'إعادة الإرسال بعد $seconds ثانية',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            if (canResend) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  // Handle resend OTP
                  setState(() {});
                },
                child: ShaderMask(
                  shaderCallback: (bounds) => 
                      AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    'إعادة إرسال',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}