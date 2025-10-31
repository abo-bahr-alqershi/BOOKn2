import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({
    required this.user,
  });

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class AuthLoginSuccess extends AuthState {
  final User user;

  const AuthLoginSuccess({
    required this.user,
  });

  @override
  List<Object?> get props => [user];
}

class AuthRegistrationSuccess extends AuthState {
  final User user;

  const AuthRegistrationSuccess({
    required this.user,
  });

  @override
  List<Object?> get props => [user];
}

class AuthLogoutSuccess extends AuthState {
  const AuthLogoutSuccess();
}

class AuthPasswordResetSent extends AuthState {
  final String message;

  const AuthPasswordResetSent({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class AuthProfileUpdateSuccess extends AuthState {
  final User user;

  const AuthProfileUpdateSuccess({
    required this.user,
  });

  @override
  List<Object?> get props => [user];
}

class AuthProfileImageUploadSuccess extends AuthState {
  final User user;

  const AuthProfileImageUploadSuccess({
    required this.user,
  });

  @override
  List<Object?> get props => [user];
}

class AuthPasswordChangeSuccess extends AuthState {
  final String message;

  const AuthPasswordChangeSuccess({
    this.message = 'تم تغيير كلمة المرور بنجاح',
  });

  @override
  List<Object?> get props => [message];
}