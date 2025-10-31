// lib/features/admin_properties/data/models/policy_model.dart

import '../../domain/entities/policy.dart';

class PolicyModel extends Policy {
  const PolicyModel({
    required String id,
    required String propertyId,
    required PolicyType policyType,
    required String description,
    required String rules,
    bool isActive = true,
    DateTime? effectiveDate,
  }) : super(
    id: id,
    propertyId: propertyId,
    policyType: policyType,
    description: description,
    rules: rules,
    isActive: isActive,
    effectiveDate: effectiveDate,
  );
  
  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    return PolicyModel(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      policyType: _parsePolicyType(json['policyType']),
      description: json['description'] as String,
      rules: json['rules'] as String,
      isActive: json['isActive'] as bool? ?? true,
      effectiveDate: json['effectiveDate'] != null
          ? DateTime.parse(json['effectiveDate'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'policyType': _policyTypeToString(policyType),
      'description': description,
      'rules': rules,
      'isActive': isActive,
      if (effectiveDate != null) 'effectiveDate': effectiveDate!.toIso8601String(),
    };
  }
  
  static PolicyType _parsePolicyType(dynamic value) {
    if (value is int) {
      switch (value) {
        case 0:
          return PolicyType.cancellation;
        case 1:
          return PolicyType.checkIn;
        case 2:
          return PolicyType.checkOut;
        case 3:
          return PolicyType.payment;
        case 4:
          return PolicyType.smoking;
        case 5:
          return PolicyType.pets;
        case 6:
          return PolicyType.damage;
        default:
          return PolicyType.other;
      }
    }
    
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'cancellation':
          return PolicyType.cancellation;
        case 'checkin':
          return PolicyType.checkIn;
        case 'checkout':
          return PolicyType.checkOut;
        case 'payment':
          return PolicyType.payment;
        case 'smoking':
          return PolicyType.smoking;
        case 'pets':
          return PolicyType.pets;
        case 'damage':
          return PolicyType.damage;
        default:
          return PolicyType.other;
      }
    }
    
    return PolicyType.other;
  }
  
  static String _policyTypeToString(PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return 'Cancellation';
      case PolicyType.checkIn:
        return 'CheckIn';
      case PolicyType.checkOut:
        return 'CheckOut';
      case PolicyType.payment:
        return 'Payment';
      case PolicyType.smoking:
        return 'Smoking';
      case PolicyType.pets:
        return 'Pets';
      case PolicyType.damage:
        return 'Damage';
      case PolicyType.other:
        return 'Other';
    }
  }
}