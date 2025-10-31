import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../repositories/payments_repository.dart';

class VoidPaymentUseCase implements UseCase<bool, VoidPaymentParams> {
  final PaymentsRepository repository;

  VoidPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(VoidPaymentParams params) async {
    return await repository.voidPayment(paymentId: params.paymentId);
  }
}

class VoidPaymentParams extends Equatable {
  final String paymentId;

  const VoidPaymentParams({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}
