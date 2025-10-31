import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FuturisticSocialButton(
          icon: 'assets/icons/google.svg',
          fallbackIcon: Icons.g_mobiledata,
          label: 'Google',
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderColor: Colors.white.withOpacity(0.2),
          onPressed: () => _handleSocialLogin(
            context,
            SocialLoginProvider.google,
          ),
        ),
        const SizedBox(height: 16),
        _FuturisticSocialButton(
          icon: 'assets/icons/facebook.svg',
          fallbackIcon: Icons.facebook,
          label: 'Facebook',
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1877F2).withOpacity(0.2),
              const Color(0xFF1877F2).withOpacity(0.1),
            ],
          ),
          borderColor: const Color(0xFF1877F2).withOpacity(0.3),
          onPressed: () => _handleSocialLogin(
            context,
            SocialLoginProvider.facebook,
          ),
        ),
        const SizedBox(height: 16),
        _FuturisticSocialButton(
          icon: 'assets/icons/apple.svg',
          fallbackIcon: Icons.apple,
          label: 'Apple',
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderColor: Colors.white.withOpacity(0.2),
          onPressed: () => _handleSocialLogin(
            context,
            SocialLoginProvider.apple,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSocialLogin(BuildContext context, SocialLoginProvider provider) async {
    try {
      switch (provider) {
        case SocialLoginProvider.google:
          const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: 'REPLACE_WITH_WEB_CLIENT_ID');
          final googleSignIn = GoogleSignIn(scopes: ['email'], serverClientId: serverClientId);
          final account = await googleSignIn.signIn();
          if (account == null) return;
          final auth = await account.authentication;
          final idToken = auth.idToken;
          if (idToken == null || idToken.isEmpty) return;
          // ignore: use_build_context_synchronously
          context.read<AuthBloc>().add(
            SocialLoginEvent(provider: provider, token: idToken),
          );
          break;
        case SocialLoginProvider.facebook:
          final res = await FacebookAuth.instance.login(permissions: ['public_profile', 'email']);
          if (res.status != LoginStatus.success) return;
          final accessToken = res.accessToken?.token;
          if (accessToken == null || accessToken.isEmpty) return;
          // ignore: use_build_context_synchronously
          context.read<AuthBloc>().add(
            SocialLoginEvent(provider: provider, token: accessToken),
          );
          break;
        case SocialLoginProvider.apple:
          return;
      }
    } catch (_) {
      return;
    }
  }
}

class _FuturisticSocialButton extends StatefulWidget {
  final String icon;
  final IconData fallbackIcon;
  final String label;
  final LinearGradient gradient;
  final Color borderColor;
  final VoidCallback onPressed;

  const _FuturisticSocialButton({
    required this.icon,
    required this.fallbackIcon,
    required this.label,
    required this.gradient,
    required this.borderColor,
    required this.onPressed,
  });

  @override
  State<_FuturisticSocialButton> createState() => 
      _FuturisticSocialButtonState();
}

class _FuturisticSocialButtonState extends State<_FuturisticSocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _animationController.forward();
        setState(() => _isHovered = true);
      },
      onTapUp: (_) {
        _animationController.reverse();
        setState(() => _isHovered = false);
        widget.onPressed();
      },
      onTapCancel: () {
        _animationController.reverse();
        setState(() => _isHovered = false);
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? widget.borderColor
                    : widget.borderColor.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.borderColor.withOpacity(0.3),
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPressed,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.fallbackIcon,
                            size: 24,
                            color: AppTheme.textWhite,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'تسجيل الدخول بـ ${widget.label}',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppTheme.textWhite,
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
        ),
      ),
    );
  }
}