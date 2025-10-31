// lib/features/auth/presentation/widgets/otp_input_widget.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
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
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shakeAnimationController;
  late Animation<double> _shakeAnimation;

  int _resendCountdown = 60;
  Timer? _resendTimer;

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
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.15,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();

    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeAnimationController,
      curve: Curves.elasticIn,
    ));

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

    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _pulseAnimationController.dispose();
    _shakeAnimationController.dispose();
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
      HapticFeedback.mediumImpact();
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

  void _handlePaste(String value) {
    if (value.length >= widget.length) {
      for (int i = 0; i < widget.length; i++) {
        _controllers[i].text = value[i];
      }
      widget.onCompleted(value.substring(0, widget.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildOtpFields(),
        const SizedBox(height: 40),
        _buildResendSection(),
        const SizedBox(height: 24),
        _buildVerifyButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.05),
            AppTheme.primaryPurple.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sms_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'أدخل رمز التحقق',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تم إرسال رمز مكون من ${widget.length} أرقام إلى رقمك',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpFields() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              _shakeAnimation.value *
                  math.sin(_shakeAnimationController.value * math.pi * 10),
              0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              widget.length,
              (index) => _buildOtpField(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtpField(int index) {
    final isFilled = _controllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;

    return AnimatedBuilder(
      animation: _scaleAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimations[index].value,
          child: Container(
            width: 52,
            height: 64,
            decoration: BoxDecoration(
              gradient: isFilled
                  ? AppTheme.primaryGradient
                  : isFocused
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withValues(alpha: 0.1),
                            AppTheme.primaryPurple.withValues(alpha: 0.08),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            AppTheme.darkCard.withValues(alpha: 0.5),
                            AppTheme.darkCard.withValues(alpha: 0.3),
                          ],
                        ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused
                    ? AppTheme.primaryBlue
                    : isFilled
                        ? Colors.transparent
                        : AppTheme.darkBorder.withValues(alpha: 0.3),
                width: isFocused ? 2 : 1,
              ),
              boxShadow: isFocused || isFilled
                  ? [
                      BoxShadow(
                        color: isFilled
                            ? AppTheme.primaryBlue.withValues(alpha: 0.4)
                            : AppTheme.primaryBlue.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Stack(
                  children: [
                    if (isFocused && !isFilled)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _pulseAnimationController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  radius: _pulseAnimationController.value,
                                  colors: [
                                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) => _onKeyDown(event, index),
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        onChanged: (value) {
                          if (value.length > 1) {
                            _handlePaste(value);
                          } else {
                            _onChanged(value, index);
                          }
                        },
                        style: AppTextStyles.heading2.copyWith(
                          color: isFilled ? Colors.white : AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),

                    // Animated cursor indicator
                    if (isFocused && !isFilled)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _pulseAnimationController,
                            builder: (context, child) {
                              return Container(
                                width: 20,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(
                                    alpha: 0.5 +
                                        (_pulseAnimationController.value * 0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResendSection() {
    final canResend = _resendCountdown == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            canResend ? Icons.refresh_rounded : Icons.timer_outlined,
            size: 20,
            color: canResend
                ? AppTheme.primaryBlue
                : AppTheme.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            canResend
                ? 'لم تستلم الرمز؟'
                : 'إعادة الإرسال بعد $_resendCountdown ثانية',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          if (canResend) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _startResendTimer();
                // TODO: Implement resend OTP logic
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
      ),
    );
  }

  Widget _buildVerifyButton() {
    final isComplete = _controllers.every((c) => c.text.isNotEmpty);

    return GestureDetector(
      onTap: isComplete
          ? () {
              HapticFeedback.mediumImpact();
              final otp = _controllers.map((c) => c.text).join();
              widget.onCompleted(otp);
            }
          : () {
              HapticFeedback.lightImpact();
              _shakeAnimationController.forward().then((_) {
                _shakeAnimationController.reset();
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          gradient: isComplete
              ? AppTheme.primaryGradient
              : LinearGradient(
                  colors: [
                    AppTheme.darkCard.withValues(alpha: 0.3),
                    AppTheme.darkCard.withValues(alpha: 0.2),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isComplete
                ? Colors.transparent
                : AppTheme.darkBorder.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: isComplete
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isComplete ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: isComplete
                      ? Colors.white
                      : AppTheme.textMuted.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'تحقق من الرمز',
                style: AppTextStyles.buttonLarge.copyWith(
                  color: isComplete
                      ? Colors.white
                      : AppTheme.textMuted.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
