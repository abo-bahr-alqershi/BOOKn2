import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class GetUserBookingsUseCase implements UseCase<PaginatedResult<Booking>, GetUserBookingsParams> {
  final BookingRepository repository;

  GetUserBookingsUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Booking>>> call(GetUserBookingsParams params) async {
    return await repository.getUserBookings(
      userId: params.userId,
      status: params.status,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetUserBookingsParams extends Equatable {
  final String userId;
  final String? status;
  final int pageNumber;
  final int pageSize;

  const GetUserBookingsParams({
    required this.userId,
    this.status,
    this.pageNumber = 1,
    this.pageSize = 10,
  });

  @override
  List<Object?> get props => [userId, status, pageNumber, pageSize];
}