// lib/features/admin_availability_pricing/domain/usecases/availability/clone_availability_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/availability_repository.dart';

class CloneAvailabilityUseCase
    implements UseCase<void, CloneAvailabilityParams> {
  final AvailabilityRepository repository;

  CloneAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    CloneAvailabilityParams params,
  ) async {
    return await repository.cloneAvailability(
      unitId: params.unitId,
      sourceStartDate: params.sourceStartDate,
      sourceEndDate: params.sourceEndDate,
      targetStartDate: params.targetStartDate,
      repeatCount: params.repeatCount,
    );
  }
}

class CloneAvailabilityParams extends Equatable {
  final String unitId;
  final DateTime sourceStartDate;
  final DateTime sourceEndDate;
  final DateTime targetStartDate;
  final int repeatCount;

  const CloneAvailabilityParams({
    required this.unitId,
    required this.sourceStartDate,
    required this.sourceEndDate,
    required this.targetStartDate,
    required this.repeatCount,
  });

  @override
  List<Object> get props => [
        unitId,
        sourceStartDate,
        sourceEndDate,
        targetStartDate,
        repeatCount,
      ];
}