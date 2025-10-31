import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class LoginEvent extends AuthEvent {
  final String emailOrPhone;
  final String password;
  final bool rememberMe;

  const LoginEvent({
    required this.emailOrPhone,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [emailOrPhone, password, rememberMe];
}

class RegisterEvent extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String passwordConfirmation;

  const RegisterEvent({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        phone,
        password,
        passwordConfirmation,
      ];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class ResetPasswordEvent extends AuthEvent {
  final String emailOrPhone;

  const ResetPasswordEvent({
    required this.emailOrPhone,
  });

  @override
  List<Object?> get props => [emailOrPhone];
}

class UpdateProfileEvent extends AuthEvent {
  final String name;
  final String? email;
  final String? phone;

  const UpdateProfileEvent({
    required this.name,
    this.email,
    this.phone,
  });

  @override
  List<Object?> get props => [name, email, phone];
}

class ChangePasswordEvent extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  final String newPasswordConfirmation;

  const ChangePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword, newPasswordConfirmation];
}

class UploadProfileImageEvent extends AuthEvent {
  final String imagePath;

  const UploadProfileImageEvent({
    required this.imagePath,
  });

  @override
  List<Object?> get props => [imagePath];
}

class SocialLoginEvent extends AuthEvent {
  final SocialLoginProvider provider;
  final String token;

  const SocialLoginEvent({
    required this.provider,
    required this.token,
  });

  @override
  List<Object?> get props => [provider, token];
}

enum SocialLoginProvider {
  google,
  facebook,
  apple,
}