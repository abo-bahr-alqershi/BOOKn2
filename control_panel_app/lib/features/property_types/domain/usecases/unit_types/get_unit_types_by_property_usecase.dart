import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/unit_type.dart';
import '../../repositories/unit_types_repository.dart';

class GetUnitTypesByPropertyUseCase 
    implements UseCase<PaginatedResult<UnitType>, GetUnitTypesByPropertyParams> {
  final UnitTypesRepository repository;

  GetUnitTypesByPropertyUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<UnitType>>> call(
    GetUnitTypesByPropertyParams params,
  ) async {
    return await repository.getUnitTypesByPropertyType(
      propertyTypeId: params.propertyTypeId,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetUnitTypesByPropertyParams extends Equatable {
  final String propertyTypeId;
  final int pageNumber;
  final int pageSize;

  const GetUnitTypesByPropertyParams({
    required this.propertyTypeId,
    required this.pageNumber,
    required this.pageSize,
  });

  @override
  List<Object> get props => [propertyTypeId, pageNumber, pageSize];
}