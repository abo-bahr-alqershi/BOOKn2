import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/payment.dart';
import '../../repositories/payments_repository.dart';

class RefundPaymentUseCase implements UseCase<bool, RefundPaymentParams> {
  final PaymentsRepository repository;

  RefundPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(RefundPaymentParams params) async {
    return await repository.refundPayment(
      paymentId: params.paymentId,
      refundAmount: params.refundAmount,
      refundReason: params.refundReason,
    );
  }
}

class RefundPaymentParams extends Equatable {
  final String paymentId;
  final Money refundAmount;
  final String refundReason;

  const RefundPaymentParams({
    required this.paymentId,
    required this.refundAmount,
    required this.refundReason,
  });

  @override
  List<Object> get props => [paymentId, refundAmount, refundReason];
}
