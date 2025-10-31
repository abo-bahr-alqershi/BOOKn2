// lib/features/admin_availability_pricing/domain/usecases/availability/check_availability_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/availability_repository.dart';

class CheckAvailabilityUseCase
    implements UseCase<CheckAvailabilityResponse, CheckAvailabilityParams> {
  final AvailabilityRepository repository;

  CheckAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, CheckAvailabilityResponse>> call(
    CheckAvailabilityParams params,
  ) async {
    return await repository.checkAvailability(
      unitId: params.unitId,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      adults: params.adults,
      children: params.children,
      includePricing: params.includePricing,
    );
  }
}

class CheckAvailabilityParams extends Equatable {
  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int? adults;
  final int? children;
  final bool? includePricing;

  const CheckAvailabilityParams({
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    this.adults,
    this.children,
    this.includePricing,
  });

  @override
  List<Object?> get props => [
        unitId,
        checkIn,
        checkOut,
        adults,
        children,
        includePricing,
      ];
}