import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/booking_details.dart';
import '../repositories/bookings_repository.dart';
import '../../../../../core/enums/payment_method_enum.dart';

/// 💳 UseCase لتسجيل دفعة جديدة للحجز
class RegisterBookingPaymentUseCase
    implements UseCase<Payment, RegisterPaymentParams> {
  final BookingsRepository repository;

  RegisterBookingPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, Payment>> call(RegisterPaymentParams params) async {
    return await repository.registerBookingPayment(params);
  }
}

/// 📦 Parameters لتسجيل الدفعة
class RegisterPaymentParams extends Equatable {
  final String bookingId;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final String? transactionId;
  final String? notes;
  final DateTime? paymentDate;

  const RegisterPaymentParams({
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
