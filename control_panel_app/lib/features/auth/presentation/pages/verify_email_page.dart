import 'dart:async';
import 'package:bookn_cp_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/route_constants.dart';
import '../../presentation/bloc/auth_bloc.dart';
import '../../presentation/bloc/auth_state.dart';
// Fallback simple widgets to avoid dependency on non-existing common widgets
import '../../../../injection_container.dart';
import '../../verification/bloc/email_verification_bloc.dart';
import '../../verification/bloc/email_verification_event.dart';
import '../../verification/bloc/email_verification_state.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _codeController = TextEditingController();
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _seconds = seconds);
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EmailVerificationBloc>(
      create: (_) => sl<EmailVerificationBloc>(),
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: MultiBlocListener(
              listeners: [
                BlocListener<AuthBloc, AuthState>(
                  listener: (context, aState) {
                    if (aState is AuthUnauthenticated) {
                      // بعد اكتمال عملية تسجيل الخروج، انتقل لصفحة تسجيل الدخول
                      context.go(RouteConstants.login);
                    }
                  },
                ),
              ],
              child:
                  BlocConsumer<EmailVerificationBloc, EmailVerificationState>(
                listener: (context, state) {
                  if (state is EmailVerificationSuccess) {
                    HapticFeedback.mediumImpact();
                    // بعد التحقق: امسح الجلسة الحالية وأعد المستخدم لشاشة تسجيل الدخول
                    // لتفادي بقاء توكن التسجيل الأولي وإجبار إعادة تسجيل الدخول بمستخدم مُفعّل
                    context.read<AuthBloc>().add(const LogoutEvent());
                    // انتظر تبدل الحالة إلى غير مصادق ثم انتقل
                    // ملاحظة: لو لم يتغير فوراً، نستخدم Future.microtask لضمان تنفيذ التنقل بعد الإطار الحالي
                    Future.microtask(() => context.go(RouteConstants.login));
                  } else if (state is EmailVerificationError) {
                    _showError(state.message);
                  } else if (state is EmailVerificationCodeResent) {
                    _startTimer(state.retryAfterSeconds ?? 60);
                  }
                },
                builder: (context, state) {
                  final authState = context.watch<AuthBloc>().state;
                  final email = authState is AuthAuthenticated
                      ? authState.user.email
                      : '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'تأكيد البريد الإلكتروني',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading2
                            .copyWith(color: AppTheme.textWhite),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أدخل رمز التحقق المرسل إلى: $email',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption
                            .copyWith(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.darkBorder.withValues(alpha: 0.2),
                              width: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: AppTextStyles.caption
                              .copyWith(color: AppTheme.textWhite),
                          decoration: const InputDecoration(
                            labelText: 'رمز التحقق',
                            hintText: '######',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: state is EmailVerificationLoading
                            ? null
                            : () {
                                final user = (context.read<AuthBloc>().state
                                        as AuthAuthenticated)
                                    .user;
                                context
                                    .read<EmailVerificationBloc>()
                                    .add(VerifyEmailSubmitted(
                                      userId: user.userId,
                                      email: user.email,
                                      code: _codeController.text.trim(),
                                    ));
                              },
                        child: state is EmailVerificationLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('تأكيد'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed:
                            _seconds > 0 || state is EmailVerificationLoading
                                ? null
                                : () {
                                    final user = (context.read<AuthBloc>().state
                                            as AuthAuthenticated)
                                        .user;
                                    context
                                        .read<EmailVerificationBloc>()
                                        .add(ResendCodePressed(
                                          userId: user.userId,
                                          email: user.email,
                                        ));
                                  },
                        child: Text(
                          _seconds > 0
                              ? 'أعد الإرسال بعد $_seconds ث'
                              : 'إعادة إرسال الرمز',
                          style: AppTextStyles.caption.copyWith(
                            color: _seconds > 0
                                ? AppTheme.textMuted
                                : AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
