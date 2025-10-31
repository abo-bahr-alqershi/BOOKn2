import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/property_type.dart';
import '../../repositories/property_types_repository.dart';

class GetAllPropertyTypesUseCase 
    implements UseCase<PaginatedResult<PropertyType>, GetAllPropertyTypesParams> {
  final PropertyTypesRepository repository;

  GetAllPropertyTypesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<PropertyType>>> call(
    GetAllPropertyTypesParams params,
  ) async {
    return await repository.getAllPropertyTypes(
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetAllPropertyTypesParams extends Equatable {
  final int pageNumber;
  final int pageSize;

  const GetAllPropertyTypesParams({
    required this.pageNumber,
    required this.pageSize,
  });

  @override
  List<Object> get props => [pageNumber, pageSize];
}