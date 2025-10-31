// lib/features/admin_properties/data/models/map_marker_model.dart

import '../../domain/entities/map_location.dart';

class MapMarkerModel extends MapMarker {
  const MapMarkerModel({
    required String id,
    required Coordinates coordinates,
    required String name,
    String? address,
    String? description,
    String? icon,
    String? color,
    required MarkerType type,
    bool isSelected = false,
    bool isFeatured = false,
    MarkerPrice? price,
    double? rating,
    bool isAvailable = true,
  }) : super(
    id: id,
    coordinates: coordinates,
    name: name,
    address: address,
    description: description,
    icon: icon,
    color: color,
    type: type,
    isSelected: isSelected,
    isFeatured: isFeatured,
    price: price,
    rating: rating,
    isAvailable: isAvailable,
  );
  
  factory MapMarkerModel.fromJson(Map<String, dynamic> json) {
    return MapMarkerModel(
      id: json['id'] as String,
      coordinates: CoordinatesModel.fromJson(json['coordinates']),
      name: json['name'] as String,
      address: json['address'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      type: _parseMarkerType(json['type']),
      isSelected: json['isSelected'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      price: json['price'] != null
          ? MarkerPriceModel.fromJson(json['price'])
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coordinates': (coordinates as CoordinatesModel).toJson(),
      'name': name,
      'address': address,
      'description': description,
      'icon': icon,
      'color': color,
      'type': _markerTypeToString(type),
      'isSelected': isSelected,
      'isFeatured': isFeatured,
      if (price != null) 'price': (price as MarkerPriceModel).toJson(),
      'rating': rating,
      'isAvailable': isAvailable,
    };
  }
  
  static MarkerType _parseMarkerType(String value) {
    switch (value.toLowerCase()) {
      case 'property':
        return MarkerType.property;
      case 'unit':
        return MarkerType.unit;
      case 'amenity':
        return MarkerType.amenity;
      default:
        return MarkerType.custom;
    }
  }
  
  static String _markerTypeToString(MarkerType type) {
    switch (type) {
      case MarkerType.property:
        return 'property';
      case MarkerType.unit:
        return 'unit';
      case MarkerType.amenity:
        return 'amenity';
      case MarkerType.custom:
        return 'custom';
    }
  }
}

class CoordinatesModel extends Coordinates {
  const CoordinatesModel({
    required double latitude,
    required double longitude,
  }) : super(latitude: latitude, longitude: longitude);
  
  factory CoordinatesModel.fromJson(Map<String, dynamic> json) {
    return CoordinatesModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class MarkerPriceModel extends MarkerPrice {
  const MarkerPriceModel({
    required double amount,
    required String currency,
  }) : super(amount: amount, currency: currency);
  
  factory MarkerPriceModel.fromJson(Map<String, dynamic> json) {
    return MarkerPriceModel(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
    };
  }
}