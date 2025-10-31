// lib/features/admin_properties/domain/usecases/policies/create_policy_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../entities/policy.dart';
import '../../repositories/policies_repository.dart';

class CreatePolicyParams {
  final String propertyId;
  final PolicyType policyType;
  final String description;
  final String rules;
  
  CreatePolicyParams({
    required this.propertyId,
    required this.policyType,
    required this.description,
    required this.rules,
  });
  
  Map<String, dynamic> toJson() => {
    'propertyId': propertyId,
    'policyType': policyType.index.toString(),
    'description': description,
    'rules': rules,
  };
}

class CreatePolicyUseCase implements UseCase<String, CreatePolicyParams> {
  final PoliciesRepository repository;
  
  CreatePolicyUseCase(this.repository);
  
  @override
  Future<Either<Failure, String>> call(CreatePolicyParams params) async {
    return await repository.createPolicy(params.toJson());
  }
}