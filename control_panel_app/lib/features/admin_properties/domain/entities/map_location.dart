// lib/features/admin_properties/domain/entities/map_location.dart

import 'package:equatable/equatable.dart';
import 'dart:math' as math;

class Coordinates extends Equatable {
  final double latitude;
  final double longitude;
  
  const Coordinates({
    required this.latitude,
    required this.longitude,
  });
  
  double distanceTo(Coordinates other) {
    // Haversine formula for distance calculation
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(other.latitude - latitude);
    final double dLon = _toRadians(other.longitude - longitude);
    
    final double a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(latitude)) * 
      math.cos(_toRadians(other.latitude)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }
  
  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }
  
  @override
  List<Object> get props => [latitude, longitude];
}

class GeoBounds extends Equatable {
  final Coordinates northeast;
  final Coordinates southwest;
  
  const GeoBounds({
    required this.northeast,
    required this.southwest,
  });
  
  bool contains(Coordinates point) {
    return point.latitude >= southwest.latitude &&
           point.latitude <= northeast.latitude &&
           point.longitude >= southwest.longitude &&
           point.longitude <= northeast.longitude;
  }
  
  Coordinates get center {
    return Coordinates(
      latitude: (northeast.latitude + southwest.latitude) / 2,
      longitude: (northeast.longitude + southwest.longitude) / 2,
    );
  }
  
  @override
  List<Object> get props => [northeast, southwest];
}

enum MarkerType { property, unit, amenity, custom }

class MapMarker extends Equatable {
  final String id;
  final Coordinates coordinates;
  final String name;
  final String? address;
  final String? description;
  final String? icon;
  final String? color;
  final MarkerType type;
  final bool isSelected;
  final bool isFeatured;
  final MarkerPrice? price;
  final double? rating;
  final bool isAvailable;
  
  const MapMarker({
    required this.id,
    required this.coordinates,
    required this.name,
    this.address,
    this.description,
    this.icon,
    this.color,
    required this.type,
    this.isSelected = false,
    this.isFeatured = false,
    this.price,
    this.rating,
    this.isAvailable = true,
  });
  
  @override
  List<Object?> get props => [
    id, coordinates, name, address, description,
    icon, color, type, isSelected, isFeatured,
    price, rating, isAvailable,
  ];
}

class MarkerPrice extends Equatable {
  final double amount;
  final String currency;
  
  const MarkerPrice({
    required this.amount,
    required this.currency,
  });
  
  String get formatted => '$currency ${amount.toStringAsFixed(2)}';
  
  @override
  List<Object> get props => [amount, currency];
}