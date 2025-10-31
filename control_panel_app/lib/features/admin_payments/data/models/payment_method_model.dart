import '../../../../../core/enums/payment_method_enum.dart';

/// Model لمعلومات طريقة الدفع
class PaymentMethodModel {
  final PaymentMethod method;
  final String displayName;
  final String icon;
  final bool isActive;
  final bool isOnline;
  final double? processingFee;
  final String? description;
  final Map<String, dynamic>? configuration;

  PaymentMethodModel({
    required this.method,
    required this.displayName,
    required this.icon,
    required this.isActive,
    required this.isOnline,
    this.processingFee,
    this.description,
    this.configuration,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      method: PaymentMethodExtension.fromBackendValue(json['methodId'] ?? 6),
      displayName: json['displayName'] ?? '',
      icon: json['icon'] ?? 'payment',
      isActive: json['isActive'] ?? true,
      isOnline: json['isOnline'] ?? false,
      processingFee: (json['processingFee'] ?? 0).toDouble(),
      description: json['description'],
      configuration: json['configuration'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'methodId': method.backendValue,
      'displayName': displayName,
      'icon': icon,
      'isActive': isActive,
      'isOnline': isOnline,
      if (processingFee != null) 'processingFee': processingFee,
      if (description != null) 'description': description,
      if (configuration != null) 'configuration': configuration,
    };
  }
}
