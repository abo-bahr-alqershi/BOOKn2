// lib/features/admin_properties/presentation/bloc/policies/policies_event.dart

part of 'policies_bloc.dart';

abstract class PoliciesEvent extends Equatable {
  const PoliciesEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadPoliciesEvent extends PoliciesEvent {
  final String? propertyId;
  final PolicyType? policyType;
  
  const LoadPoliciesEvent({
    this.propertyId,
    this.policyType,
  });
  
  @override
  List<Object?> get props => [propertyId, policyType];
}

class CreatePolicyEvent extends PoliciesEvent {
  final String propertyId;
  final PolicyType policyType;
  final String description;
  final String rules;
  
  const CreatePolicyEvent({
    required this.propertyId,
    required this.policyType,
    required this.description,
    required this.rules,
  });
  
  @override
  List<Object> get props => [propertyId, policyType, description, rules];
}

class UpdatePolicyEvent extends PoliciesEvent {
  final String policyId;
  final PolicyType? policyType;
  final String? description;
  final String? rules;
  
  const UpdatePolicyEvent({
    required this.policyId,
    this.policyType,
    this.description,
    this.rules,
  });
  
  @override
  List<Object?> get props => [policyId, policyType, description, rules];
}

class DeletePolicyEvent extends PoliciesEvent {
  final String policyId;
  
  const DeletePolicyEvent(this.policyId);
  
  @override
  List<Object> get props => [policyId];
}