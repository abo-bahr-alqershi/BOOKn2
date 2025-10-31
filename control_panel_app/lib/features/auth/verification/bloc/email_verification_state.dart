import 'package:equatable/equatable.dart';

abstract class EmailVerificationState extends Equatable {
  const EmailVerificationState();
  @override
  List<Object?> get props => [];
}

class EmailVerificationInitial extends EmailVerificationState {
  const EmailVerificationInitial();
}

class EmailVerificationLoading extends EmailVerificationState {
  const EmailVerificationLoading();
}

class EmailVerificationSuccess extends EmailVerificationState {
  const EmailVerificationSuccess();
}

class EmailVerificationError extends EmailVerificationState {
  final String message;
  const EmailVerificationError(this.message);
  @override
  List<Object?> get props => [message];
}

class EmailVerificationCodeResent extends EmailVerificationState {
  final int? retryAfterSeconds;
  const EmailVerificationCodeResent({this.retryAfterSeconds});
  @override
  List<Object?> get props => [retryAfterSeconds];
}

