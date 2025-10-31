import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/policy.dart';
import '../repositories/policies_repository.dart';

class CreatePolicyUseCase implements UseCase<String, CreatePolicyParams> {
  final PoliciesRepository repository;

  CreatePolicyUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreatePolicyParams params) async {
    return await repository.createPolicy(
      propertyId: params.propertyId,
      type: params.type,
      description: params.description,
      rules: params.rules,
      cancellationWindowDays: params.cancellationWindowDays,
      requireFullPaymentBeforeConfirmation: params.requireFullPaymentBeforeConfirmation,
      minimumDepositPercentage: params.minimumDepositPercentage,
      minHoursBeforeCheckIn: params.minHoursBeforeCheckIn,
    );
  }
}

class CreatePolicyParams extends Equatable {
  final String propertyId;
  final PolicyType type;
  final String description;
  final String rules;
  final int cancellationWindowDays;
  final bool requireFullPaymentBeforeConfirmation;
  final double minimumDepositPercentage;
  final int minHoursBeforeCheckIn;

  const CreatePolicyParams({
    required this.propertyId,
    required this.type,
    required this.description,
    required this.rules,
    this.cancellationWindowDays = 0,
    this.requireFullPaymentBeforeConfirmation = false,
    this.minimumDepositPercentage = 0.0,
    this.minHoursBeforeCheckIn = 0,
  });

  @override
  List<Object?> get props => [
        propertyId,
        type,
        description,
        rules,
        cancellationWindowDays,
        requireFullPaymentBeforeConfirmation,
        minimumDepositPercentage,
        minHoursBeforeCheckIn,
      ];
}
