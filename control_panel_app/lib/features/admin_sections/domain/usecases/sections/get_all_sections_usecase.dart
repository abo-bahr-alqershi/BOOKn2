import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/entities/section.dart';
import '../../../domain/repositories/sections_repository.dart';
import '../../../../../core/enums/section_target.dart';
import '../../../../../core/enums/section_type.dart';
import '../../../../../core/enums/section_content_type.dart';

class GetAllSectionsUseCase implements UseCase<PaginatedResult<Section>, GetAllSectionsParams> {
  final SectionsRepository repository;
  GetAllSectionsUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Section>>> call(GetAllSectionsParams params) {
    return repository.getSections(
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      target: params.target,
      type: params.type,
      contentType: params.contentType,
    );
  }
}

class GetAllSectionsParams extends Equatable {
  final int? pageNumber;
  final int? pageSize;
  final SectionTarget? target;
  final SectionTypeEnum? type;
  final SectionContentType? contentType;

  const GetAllSectionsParams({
    this.pageNumber,
    this.pageSize,
    this.target,
    this.type,
    this.contentType,
  });

  @override
  List<Object?> get props => [pageNumber, pageSize, target, type, contentType];
}

