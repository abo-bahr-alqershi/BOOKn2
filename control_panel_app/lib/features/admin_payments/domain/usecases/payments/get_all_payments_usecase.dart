import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../../../../../core/enums/payment_method_enum.dart';
import '../../entities/payment.dart';
import '../../repositories/payments_repository.dart';

class GetAllPaymentsUseCase
    implements UseCase<PaginatedResult<Payment>, GetAllPaymentsParams> {
  final PaymentsRepository repository;

  GetAllPaymentsUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Payment>>> call(
    GetAllPaymentsParams params,
  ) async {
    return await repository.getAllPayments(
      status: params.status,
      method: params.method,
      bookingId: params.bookingId,
      userId: params.userId,
      propertyId: params.propertyId,
      unitId: params.unitId,
      minAmount: params.minAmount,
      maxAmount: params.maxAmount,
      startDate: params.startDate,
      endDate: params.endDate,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetAllPaymentsParams extends Equatable {
  final PaymentStatus? status;
  final PaymentMethod? method;
  final String? bookingId;
  final String? userId;
  final String? propertyId;
  final String? unitId;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? pageNumber;
  final int? pageSize;

  const GetAllPaymentsParams({
    this.status,
    this.method,
    this.bookingId,
    this.userId,
    this.propertyId,
    this.unitId,
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
    this.pageNumber,
    this.pageSize,
  });

  @override
  List<Object?> get props => [
        status,
        method,
        bookingId,
        userId,
        propertyId,
        unitId,
        minAmount,
        maxAmount,
        startDate,
        endDate,
        pageNumber,
        pageSize,
      ];
}
