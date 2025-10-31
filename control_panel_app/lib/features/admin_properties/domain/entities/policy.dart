// lib/features/admin_properties/domain/entities/policy.dart

import 'package:equatable/equatable.dart';

enum PolicyType {
  cancellation,
  checkIn,
  checkOut,
  payment,
  smoking,
  pets,
  damage,
  other,
}

class Policy extends Equatable {
  final String id;
  final String propertyId;
  final PolicyType policyType;
  final String description;
  final String rules;
  final bool isActive;
  final DateTime? effectiveDate;
  
  const Policy({
    required this.id,
    required this.propertyId,
    required this.policyType,
    required this.description,
    required this.rules,
    this.isActive = true,
    this.effectiveDate,
  });
  
  String get policyTypeLabel {
    switch (policyType) {
      case PolicyType.cancellation:
        return 'سياسة الإلغاء';
      case PolicyType.checkIn:
        return 'تسجيل الدخول';
      case PolicyType.checkOut:
        return 'تسجيل الخروج';
      case PolicyType.payment:
        return 'الدفع';
      case PolicyType.smoking:
        return 'التدخين';
      case PolicyType.pets:
        return 'الحيوانات الأليفة';
      case PolicyType.damage:
        return 'الأضرار';
      case PolicyType.other:
        return 'أخرى';
    }
  }
  
  @override
  List<Object?> get props => [
    id, propertyId, policyType, description,
    rules, isActive, effectiveDate,
  ];
}