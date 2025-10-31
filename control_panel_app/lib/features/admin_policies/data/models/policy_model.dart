import '../../domain/entities/policy.dart';

class PolicyModel extends Policy {
  const PolicyModel({
    required String id,
    required String propertyId,
    String? propertyName,
    required PolicyType type,
    required String description,
    required String rules,
    int cancellationWindowDays = 0,
    bool requireFullPaymentBeforeConfirmation = false,
    double minimumDepositPercentage = 0.0,
    int minHoursBeforeCheckIn = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) : super(
          id: id,
          propertyId: propertyId,
          propertyName: propertyName,
          type: type,
          description: description,
          rules: rules,
          cancellationWindowDays: cancellationWindowDays,
          requireFullPaymentBeforeConfirmation: requireFullPaymentBeforeConfirmation,
          minimumDepositPercentage: minimumDepositPercentage,
          minHoursBeforeCheckIn: minHoursBeforeCheckIn,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isActive: isActive,
        );

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    try {
      final model = PolicyModel(
        id: (json['id'] ?? json['policyId'] ?? json['Id'] ?? '').toString(),
        propertyId: (json['propertyId'] ?? json['PropertyId'] ?? '').toString(),
        propertyName: json['propertyName'] ?? json['PropertyName'],
        type: _parsePolicyType(json['type'] ?? json['policyType'] ?? json['Type'] ?? json['PolicyType']),
        description: json['description'] ?? json['Description'] ?? '',
        rules: json['rules'] ?? json['Rules'] ?? '{}',
        cancellationWindowDays: json['cancellationWindowDays'] ?? json['CancellationWindowDays'] ?? 0,
        requireFullPaymentBeforeConfirmation: json['requireFullPaymentBeforeConfirmation'] ?? json['RequireFullPaymentBeforeConfirmation'] ?? false,
        minimumDepositPercentage: (json['minimumDepositPercentage'] ?? json['MinimumDepositPercentage'] ?? 0).toDouble(),
        minHoursBeforeCheckIn: json['minHoursBeforeCheckIn'] ?? json['MinHoursBeforeCheckIn'] ?? 0,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : (json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt']) : null),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : (json['UpdatedAt'] != null ? DateTime.parse(json['UpdatedAt']) : null),
        isActive: json['isActive'] ?? json['IsActive'] ?? json['active'] ?? true,
      );
      
      return model;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      if (propertyName != null) 'propertyName': propertyName,
      'type': type.apiValue,
      'description': description,
      'rules': rules,
      'cancellationWindowDays': cancellationWindowDays,
      'requireFullPaymentBeforeConfirmation': requireFullPaymentBeforeConfirmation,
      'minimumDepositPercentage': minimumDepositPercentage,
      'minHoursBeforeCheckIn': minHoursBeforeCheckIn,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory PolicyModel.fromEntity(Policy entity) {
    return PolicyModel(
      id: entity.id,
      propertyId: entity.propertyId,
      propertyName: entity.propertyName,
      type: entity.type,
      description: entity.description,
      rules: entity.rules,
      cancellationWindowDays: entity.cancellationWindowDays,
      requireFullPaymentBeforeConfirmation: entity.requireFullPaymentBeforeConfirmation,
      minimumDepositPercentage: entity.minimumDepositPercentage,
      minHoursBeforeCheckIn: entity.minHoursBeforeCheckIn,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
    );
  }

  static PolicyType _parsePolicyType(dynamic value) {
    if (value == null) return PolicyType.cancellation;
    
    if (value is int) {
      switch (value) {
        case 0:
          return PolicyType.cancellation;
        case 1:
          return PolicyType.checkIn;
        case 2:
          return PolicyType.children;
        case 3:
          return PolicyType.pets;
        case 4:
          return PolicyType.payment;
        case 5:
          return PolicyType.modification;
        default:
          return PolicyType.cancellation;
      }
    }
    
    return PolicyType.fromString(value.toString());
  }
}

/// 📊 Model لإحصائيات السياسات
class PolicyStatsModel {
  final int totalPolicies;
  final int activePolicies;
  final int policiesByType;
  final Map<String, int> policyTypeDistribution;
  final double averageCancellationWindow;

  PolicyStatsModel({
    required this.totalPolicies,
    required this.activePolicies,
    required this.policiesByType,
    required this.policyTypeDistribution,
    required this.averageCancellationWindow,
  });

  factory PolicyStatsModel.fromJson(Map<String, dynamic> json) {
    return PolicyStatsModel(
      totalPolicies: json['totalPolicies'] ?? 0,
      activePolicies: json['activePolicies'] ?? 0,
      policiesByType: json['policiesByType'] ?? 0,
      policyTypeDistribution: Map<String, int>.from(json['policyTypeDistribution'] ?? {}),
      averageCancellationWindow: (json['averageCancellationWindow'] ?? 0).toDouble(),
    );
  }

  PolicyStats toEntity() {
    return PolicyStats(
      totalPolicies: totalPolicies,
      activePolicies: activePolicies,
      policiesByType: policiesByType,
      policyTypeDistribution: policyTypeDistribution,
      averageCancellationWindow: averageCancellationWindow,
    );
  }
}
