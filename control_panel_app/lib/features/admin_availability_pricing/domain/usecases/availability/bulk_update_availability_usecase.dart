// lib/features/admin_availability_pricing/domain/usecases/availability/bulk_update_availability_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/availability_repository.dart';

class BulkUpdateAvailabilityUseCase
    implements UseCase<void, BulkUpdateAvailabilityParams> {
  final AvailabilityRepository repository;

  BulkUpdateAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    BulkUpdateAvailabilityParams params,
  ) async {
    return await repository.bulkUpdateAvailability(
      unitId: params.unitId,
      periods: params.periods,
      overwriteExisting: params.overwriteExisting,
    );
  }
}

class BulkUpdateAvailabilityParams extends Equatable {
  final String unitId;
  final List<AvailabilityPeriod> periods;
  final bool overwriteExisting;

  const BulkUpdateAvailabilityParams({
    required this.unitId,
    required this.periods,
    required this.overwriteExisting,
  });

  @override
  List<Object> get props => [unitId, periods, overwriteExisting];
}