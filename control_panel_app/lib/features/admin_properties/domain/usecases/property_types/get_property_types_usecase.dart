// lib/features/admin_properties/domain/usecases/property_types/get_property_types_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../../entities/property_type.dart';
import '../../repositories/property_types_repository.dart';

class GetPropertyTypesParams {
  final int? pageNumber;
  final int? pageSize;
  
  GetPropertyTypesParams({
    this.pageNumber = 1,
    this.pageSize = 10,
  });
}

class GetPropertyTypesUseCase implements UseCase<PaginatedResult<PropertyType>, GetPropertyTypesParams> {
  final PropertyTypesRepository repository;
  
  GetPropertyTypesUseCase(this.repository);
  
  @override
  Future<Either<Failure, PaginatedResult<PropertyType>>> call(GetPropertyTypesParams params) async {
    return await repository.getAllPropertyTypes(
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}