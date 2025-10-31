part of 'register_payment_bloc.dart';

/// 📋 Base event class for register payment
abstract class RegisterPaymentEvent extends Equatable {
  const RegisterPaymentEvent();

  @override
  List<Object?> get props => [];
}

/// 💳 Event to register a new payment
class RegisterNewPaymentEvent extends RegisterPaymentEvent {
  final String bookingId;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final String? transactionId;
  final String? notes;
  final DateTime? paymentDate;

  const RegisterNewPaymentEvent({
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.transactionId,
    this.notes,
    this.paymentDate,
  });

  @override
  List<Object?> get props => [
        bookingId,
        amount,
        currency,
        paymentMethod,
        transactionId,
        notes,
        paymentDate,
      ];
}

/// 🔄 Event to reset the registration form
class ResetRegisterPaymentEvent extends RegisterPaymentEvent {}
