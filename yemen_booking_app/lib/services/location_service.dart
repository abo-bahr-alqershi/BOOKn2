import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Location settings for high accuracy
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Request location permission
  Future<LocationPermissionStatus> requestLocationPermission() async {
    final status = await Permission.location.request();
    
    switch (status) {
      case PermissionStatus.granted:
        return LocationPermissionStatus.granted;
      case PermissionStatus.denied:
        return LocationPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        return LocationPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return LocationPermissionStatus.restricted;
      default:
        return LocationPermissionStatus.unknown;
    }
  }

  // Check location permission
  Future<LocationPermissionStatus> checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.permanentlyDenied;
      default:
        return LocationPermissionStatus.unknown;
    }
  }

  // Get current position
  Future<LocationData> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceException(
          'خدمات الموقع معطلة. يرجى تفعيلها من الإعدادات',
          LocationErrorType.serviceDisabled,
        );
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationServiceException(
            'تم رفض صلاحية الوصول للموقع',
            LocationErrorType.permissionDenied,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationServiceException(
          'تم رفض صلاحية الوصول للموقع بشكل دائم. يرجى تفعيلها من الإعدادات',
          LocationErrorType.permissionDeniedForever,
        );
      }

      // Get position using settings
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _locationSettings.accuracy,
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
        heading: position.heading,
        timestamp: position.timestamp,
      );
    } catch (e) {
      if (e is LocationServiceException) {
        rethrow;
      }
      throw LocationServiceException(
        'حدث خطأ في الحصول على الموقع: ${e.toString()}',
        LocationErrorType.unknown,
      );
    }
  }

  // Get last known position
  Future<LocationData?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        return LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
          speedAccuracy: position.speedAccuracy,
          heading: position.heading,
          timestamp: position.timestamp,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Get address from coordinates
  Future<AddressData?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        localeIdentifier: 'ar',
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return AddressData(
          street: placemark.street,
          subLocality: placemark.subLocality,
          locality: placemark.locality,
          administrativeArea: placemark.administrativeArea,
          country: placemark.country,
          postalCode: placemark.postalCode,
          formattedAddress: _formatAddress(placemark),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get coordinates from address
  Future<LocationData?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LocationData(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Start location stream
  Stream<LocationData> getLocationStream({
    int distanceFilter = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).map((position) => LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
          speedAccuracy: position.speedAccuracy,
          heading: position.heading,
          timestamp: position.timestamp,
        ));
  }

  // Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  // Format address helper
  String _formatAddress(Placemark placemark) {
    final parts = <String>[];
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      parts.add(placemark.subLocality!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null && 
        placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }
    return parts.join('، ');
  }
}

// Data classes
class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? speedAccuracy;
  final double? heading;
  final DateTime? timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.speedAccuracy,
    this.heading,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'speedAccuracy': speedAccuracy,
        'heading': heading,
        'timestamp': timestamp?.toIso8601String(),
      };
}

class AddressData {
  final String? street;
  final String? subLocality;
  final String? locality;
  final String? administrativeArea;
  final String? country;
  final String? postalCode;
  final String formattedAddress;

  AddressData({
    this.street,
    this.subLocality,
    this.locality,
    this.administrativeArea,
    this.country,
    this.postalCode,
    required this.formattedAddress,
  });
}

// Enums
enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unknown,
}

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

// Exception
class LocationServiceException implements Exception {
  final String message;
  final LocationErrorType type;

  LocationServiceException(this.message, this.type);

  @override
  String toString() => message;
}