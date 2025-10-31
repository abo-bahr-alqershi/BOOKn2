import 'package:equatable/equatable.dart';

abstract class EmailVerificationEvent extends Equatable {
  const EmailVerificationEvent();

  @override
  List<Object?> get props => [];
}

class VerifyEmailSubmitted extends EmailVerificationEvent {
  final String userId;
  final String email;
  final String code;
  const VerifyEmailSubmitted({required this.userId, required this.email, required this.code});

  @override
  List<Object?> get props => [userId, email, code];
}

class ResendCodePressed extends EmailVerificationEvent {
  final String userId;
  final String email;
  const ResendCodePressed({required this.userId, required this.email});

  @override
  List<Object?> get props => [userId, email];
}

