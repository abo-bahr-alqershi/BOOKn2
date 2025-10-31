import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/entities/property_in_section.dart';
import '../../../domain/entities/unit_in_section.dart';
import '../../../domain/repositories/sections_repository.dart';
import '../../../../../core/enums/section_target.dart';

class GetSectionItemsUseCase
    implements UseCase<PaginatedResult<dynamic>, GetSectionItemsParams> {
  final SectionsRepository repository;
  GetSectionItemsUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<dynamic>>> call(
      GetSectionItemsParams params) {
    if (params.target == SectionTarget.properties) {
      return repository
          .getPropertyItems(params.sectionId,
              pageNumber: params.pageNumber, pageSize: params.pageSize)
          .then((either) => either.map((r) => r));
    } else {
      return repository
          .getUnitItems(params.sectionId,
              pageNumber: params.pageNumber, pageSize: params.pageSize)
          .then((either) => either.map((r) => r));
    }
  }
}

class GetSectionItemsParams extends Equatable {
  final String sectionId;
  final SectionTarget target;
  final int pageNumber;
  final int pageSize;

  const GetSectionItemsParams({
    required this.sectionId,
    required this.target,
    this.pageNumber = 1,
    this.pageSize = 10,
  });

  @override
  List<Object?> get props => [sectionId, target, pageNumber, pageSize];
}

