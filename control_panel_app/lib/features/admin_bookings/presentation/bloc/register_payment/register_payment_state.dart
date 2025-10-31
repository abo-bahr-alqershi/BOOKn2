part of 'register_payment_bloc.dart';

/// 📋 Base state class for register payment
abstract class RegisterPaymentState extends Equatable {
  const RegisterPaymentState();

  @override
  List<Object?> get props => [];
}

/// 🏁 Initial state
class RegisterPaymentInitial extends RegisterPaymentState {}

/// ⏳ Loading state
class RegisterPaymentLoading extends RegisterPaymentState {}

/// ✅ Success state
class RegisterPaymentSuccess extends RegisterPaymentState {
  final Payment payment;
  final String successMessage;

  const RegisterPaymentSuccess({
    required this.payment,
    required this.successMessage,
  });

  @override
  List<Object?> get props => [payment, successMessage];
}

/// ❌ Error state
class RegisterPaymentError extends RegisterPaymentState {
  final String message;

  const RegisterPaymentError(this.message);

  @override
  List<Object> get props => [message];
}
