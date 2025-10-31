import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../../../../../core/enums/payment_method_enum.dart';
import '../../entities/payment.dart';
import '../../repositories/payments_repository.dart';

class UpdatePaymentStatusUseCase
    implements UseCase<bool, UpdatePaymentStatusParams> {
  final PaymentsRepository repository;

  UpdatePaymentStatusUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdatePaymentStatusParams params) async {
    return await repository.updatePaymentStatus(
      paymentId: params.paymentId,
      newStatus: params.newStatus,
    );
  }
}

class UpdatePaymentStatusParams extends Equatable {
  final String paymentId;
  final PaymentStatus newStatus;

  const UpdatePaymentStatusParams({
    required this.paymentId,
    required this.newStatus,
  });

  @override
  List<Object> get props => [paymentId, newStatus];
}
