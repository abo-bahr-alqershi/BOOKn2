// lib/features/home/domain/usecases/get_sections_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yemen_booking_app/core/models/paginated_result.dart' as core;
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/section.dart';
import '../repositories/home_repository.dart';

class GetSectionsUseCase implements UseCase<core.PaginatedResult<Section>, GetSectionsParams> {
  final HomeRepository repository;
  GetSectionsUseCase(this.repository);

  @override
  Future<Either<Failure, core.PaginatedResult<Section>>> call(GetSectionsParams params) async {
    if (repository is dynamic && (repository as dynamic).getSections is Function) {
      return await (repository as dynamic).getSections(
        pageNumber: params.pageNumber,
        pageSize: params.pageSize,
        target: params.target,
        type: params.type,
        forceRefresh: params.forceRefresh,
      );
    }
    return const Left(UnknownFailure('GetSectionsUseCase not implemented'));
  }
}

class GetSectionsParams extends Equatable {
  final int pageNumber;
  final int pageSize;
  final String? target;
  final String? type;
  final bool forceRefresh;

  const GetSectionsParams({
    this.pageNumber = 1,
    this.pageSize = 10,
    this.target,
    this.type,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [pageNumber, pageSize, target, type, forceRefresh];
}