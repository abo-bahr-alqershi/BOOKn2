// lib/features/home/domain/usecases/get_section_data_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yemen_booking_app/core/models/paginated_result.dart' as core;
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/section_item_models.dart';
import '../repositories/home_repository.dart';

class GetSectionDataUseCase implements UseCase<core.PaginatedResult<SectionPropertyItemModel>, GetSectionDataParams> {
  final HomeRepository repository;
  GetSectionDataUseCase(this.repository);

  @override
  Future<Either<Failure, core.PaginatedResult<SectionPropertyItemModel>>> call(GetSectionDataParams params) async {
    if (repository is dynamic && (repository as dynamic).getSectionPropertyItems is Function) {
      return await (repository as dynamic).getSectionPropertyItems(
        sectionId: params.sectionId,
        pageNumber: params.pageNumber,
        pageSize: params.pageSize,
        forceRefresh: params.forceRefresh,
      );
    }
    return const Left(UnknownFailure('GetSectionDataUseCase not implemented'));
  }
}

class GetSectionDataParams extends Equatable {
  final String sectionId;
  final int pageNumber;
  final int pageSize;
  final bool forceRefresh;

  const GetSectionDataParams({
    required this.sectionId,
    this.pageNumber = 1,
    this.pageSize = 10,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [sectionId, pageNumber, pageSize, forceRefresh];
}