import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/service.dart';
import '../repositories/services_repository.dart';

/// 🏷️ Use Case لجلب الخدمات حسب النوع
class GetServicesByTypeUseCase implements UseCase<PaginatedResult<Service>, GetServicesByTypeParams> {
  final ServicesRepository repository;

  GetServicesByTypeUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Service>>> call(GetServicesByTypeParams params) async {
    return await repository.getServicesByType(
      serviceType: params.serviceType,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetServicesByTypeParams extends Equatable {
  final String serviceType;
  final int? pageNumber;
  final int? pageSize;

  const GetServicesByTypeParams({
    required this.serviceType,
    this.pageNumber,
    this.pageSize,
  });

  @override
  List<Object?> get props => [serviceType, pageNumber, pageSize];
}