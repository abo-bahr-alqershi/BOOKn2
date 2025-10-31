import '../../domain/entities/service.dart';
import '../../domain/entities/pricing_model.dart';
import 'money_model.dart';

/// 🛎️ Model للخدمة
class ServiceModel extends Service {
  const ServiceModel({
    required super.id,
    required super.propertyId,
    required super.propertyName,
    required super.name,
    required super.price,
    required super.pricingModel,
    required super.icon,
    super.description,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // Handle pricing model from backend format
    final pricingModelData = json['pricingModel'];
    PricingModel pricingModel;
    
    if (pricingModelData is Map) {
      pricingModel = PricingModel.fromValue(pricingModelData.keys.first);
    } else {
      pricingModel = PricingModel.fromValue('${pricingModelData ?? 'PerBooking'}');
    }

    return ServiceModel(
      id: json['id'] ?? '',
      propertyId: json['propertyId'] ?? '',
      propertyName: json['propertyName'] ?? '',
      name: json['name'] ?? '',
      price: MoneyModel.fromJson(json['price'] ?? {}),
      pricingModel: pricingModel,
      icon: json['icon'] ?? 'room_service',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'name': name,
      'price': MoneyModel(
        amount: price.amount,
        currency: price.currency,
        formattedAmount: price.formattedAmount,
      ).toJson(),
      'pricingModel': pricingModel.value,
      'icon': icon,
      if (description != null) 'description': description,
    };
  }

  Service toEntity() => Service(
        id: id,
        propertyId: propertyId,
        propertyName: propertyName,
        name: name,
        price: price,
        pricingModel: pricingModel,
        icon: icon,
        description: description,
      );
}