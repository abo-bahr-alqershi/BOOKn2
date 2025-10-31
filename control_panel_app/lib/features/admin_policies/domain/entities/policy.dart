import 'package:equatable/equatable.dart';

/// 📋 Entity للسياسة
class Policy extends Equatable {
  final String id;
  final String propertyId;
  final String? propertyName;
  final PolicyType type;
  final String description;
  final String rules;
  final int cancellationWindowDays;
  final bool requireFullPaymentBeforeConfirmation;
  final double minimumDepositPercentage;
  final int minHoursBeforeCheckIn;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isActive;

  const Policy({
    required this.id,
    required this.propertyId,
    this.propertyName,
    required this.type,
    required this.description,
    required this.rules,
    this.cancellationWindowDays = 0,
    this.requireFullPaymentBeforeConfirmation = false,
    this.minimumDepositPercentage = 0.0,
    this.minHoursBeforeCheckIn = 0,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  Policy copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    PolicyType? type,
    String? description,
    String? rules,
    int? cancellationWindowDays,
    bool? requireFullPaymentBeforeConfirmation,
    double? minimumDepositPercentage,
    int? minHoursBeforeCheckIn,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Policy(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      type: type ?? this.type,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      cancellationWindowDays: cancellationWindowDays ?? this.cancellationWindowDays,
      requireFullPaymentBeforeConfirmation: requireFullPaymentBeforeConfirmation ?? this.requireFullPaymentBeforeConfirmation,
      minimumDepositPercentage: minimumDepositPercentage ?? this.minimumDepositPercentage,
      minHoursBeforeCheckIn: minHoursBeforeCheckIn ?? this.minHoursBeforeCheckIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        propertyId,
        propertyName,
        type,
        description,
        rules,
        cancellationWindowDays,
        requireFullPaymentBeforeConfirmation,
        minimumDepositPercentage,
        minHoursBeforeCheckIn,
        createdAt,
        updatedAt,
        isActive,
      ];
}

/// نوع السياسة
enum PolicyType {
  cancellation,
  checkIn,
  children,
  pets,
  payment,
  modification;

  String get displayName {
    switch (this) {
      case PolicyType.cancellation:
        return 'سياسة الإلغاء';
      case PolicyType.checkIn:
        return 'سياسة تسجيل الدخول';
      case PolicyType.children:
        return 'سياسة الأطفال';
      case PolicyType.pets:
        return 'سياسة الحيوانات الأليفة';
      case PolicyType.payment:
        return 'سياسة الدفع';
      case PolicyType.modification:
        return 'سياسة التعديل';
    }
  }

  String get apiValue {
    switch (this) {
      case PolicyType.cancellation:
        return 'Cancellation';
      case PolicyType.checkIn:
        return 'CheckIn';
      case PolicyType.children:
        return 'Children';
      case PolicyType.pets:
        return 'Pets';
      case PolicyType.payment:
        return 'Payment';
      case PolicyType.modification:
        return 'Modification';
    }
  }

  static PolicyType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cancellation':
        return PolicyType.cancellation;
      case 'checkin':
        return PolicyType.checkIn;
      case 'children':
        return PolicyType.children;
      case 'pets':
        return PolicyType.pets;
      case 'payment':
        return PolicyType.payment;
      case 'modification':
        return PolicyType.modification;
      default:
        return PolicyType.cancellation;
    }
  }
}

/// 📊 Entity لإحصائيات السياسات
class PolicyStats {
  final int totalPolicies;
  final int activePolicies;
  final int policiesByType;
  final Map<String, int> policyTypeDistribution;
  final double averageCancellationWindow;

  const PolicyStats({
    required this.totalPolicies,
    required this.activePolicies,
    required this.policiesByType,
    required this.policyTypeDistribution,
    required this.averageCancellationWindow,
  });
}
