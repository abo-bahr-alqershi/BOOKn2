import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/payment.dart';
import '../../repositories/payments_repository.dart';

class GetPaymentsByBookingUseCase
    implements UseCase<PaginatedResult<Payment>, GetPaymentsByBookingParams> {
  final PaymentsRepository repository;

  GetPaymentsByBookingUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Payment>>> call(
    GetPaymentsByBookingParams params,
  ) async {
    return await repository.getPaymentsByBooking(
      bookingId: params.bookingId,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetPaymentsByBookingParams extends Equatable {
  final String bookingId;
  final int? pageNumber;
  final int? pageSize;

  const GetPaymentsByBookingParams({
    required this.bookingId,
    this.pageNumber,
    this.pageSize,
  });

  @override
  List<Object?> get props => [bookingId, pageNumber, pageSize];
}
