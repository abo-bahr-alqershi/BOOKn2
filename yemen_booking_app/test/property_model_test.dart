import 'package:flutter_test/flutter_test.dart';
import 'package:yemen_booking_app/features/property/data/models/amenity_model.dart';
import 'package:yemen_booking_app/features/property/data/models/unit_model.dart';
import 'package:yemen_booking_app/features/property/data/models/review_model.dart';
import 'package:yemen_booking_app/features/property/data/models/property_detail_model.dart';

void main() {
  group('AmenityModel', () {
    test('fromJson and toJson should handle fallback keys', () {
      final json = {
        'amenityId': 'a1',
        'name': 'Amenity Name',
        'description': 'Description',
        'iconUrl': 'http://example.com/icon.png',
        'category': 'Category',
        'isAvailable': false,
        'displayOrder': 5,
        'createdAt': '2023-01-01T12:00:00Z',
      };
      final model = AmenityModel.fromJson(json);
      expect(model.id, 'a1');
      expect(model.name, 'Amenity Name');
      expect(model.isActive, false);
      final toJson = model.toJson();
      expect(toJson['id'], 'a1');
      expect(toJson['isActive'], false);
    });
  });

  group('UnitModel', () {
    test('fromJson and toJson should map keys correctly', () {
      final json = {
        'id': 'u1',
        'propertyId': 'p1',
        'unitTypeId': 'ut1',
        'name': 'Unit Name',
        'basePrice': {'amount': 100, 'currency': 'USD', 'exchangeRate': 1.0},
        'customFeatures': 'features',
        'isAvailable': true,
        'propertyName': 'Property1',
        'unitTypeName': 'Type1',
        'pricingMethod': 'daily',
        'fieldValues': [],
        'dynamicFields': [],
        'distanceKm': 2.5,
        'images': [],
      };
      final model = UnitModel.fromJson(json);
      expect(model.id, 'u1');
      expect(model.basePrice.amount, 100);
      expect(model.isAvailable, true);
      expect(model.pricingMethod.name, 'daily');
      final toJson = model.toJson();
      expect(toJson['id'], 'u1');
      expect(toJson['basePrice']['amount'], 100);
      expect(toJson['pricingMethod'], 'daily');
    });
  });

  group('ReviewModel', () {
    test('fromJson and toJson should map review fields', () {
      final json = {
        'id': 'r1',
        'bookingId': 'b1',
        'propertyName': 'Property1',
        'userName': 'User1',
        'cleanliness': 5,
        'service': 4,
        'location': 3,
        'value': 2,
        'averageRating': 4.0,
        'comment': 'Great',
        'responseText': 'Thanks',
        'responseDate': '2023-01-02T12:00:00Z',
        'createdAt': '2023-01-01T12:00:00Z',
        'images': [],
      };
      final model = ReviewModel.fromJson(json);
      expect(model.id, 'r1');
      expect(model.averageRating, 4.0);
      expect(model.responseText, 'Thanks');
      final toJson = model.toJson();
      expect(toJson['id'], 'r1');
      expect(toJson['responseText'], 'Thanks');
    });
  });

  group('PropertyDetailModel', () {
    test('fromJson and toJson should handle nested propertyType fallback', () {
      final json = {
        'id': 'p1',
        'name': 'Property1',
        'ownerId': 'o1',
        'propertyType': {'id': 't1', 'name': 'Type1'},
        'ownerName': 'Owner1',
        'address': 'Addr1',
        'city': 'City1',
        'latitude': 10.0,
        'longitude': 20.0,
        'starRating': 5,
        'description': 'Desc1',
        'averageRating': 4.5,
        'reviewsCount': 10,
        'viewCount': 100,
        'bookingCount': 5,
        'isFavorite': true,
        'isApproved': true,
        'createdAt': '2023-01-01T12:00:00Z',
        'images': [],
        'amenities': [],
        'services': [],
        'policies': [],
        'units': [],
      };
      final model = PropertyDetailModel.fromJson(json);
      expect(model.id, 'p1');
      expect(model.typeId, 't1');
      expect(model.typeName, 'Type1');
      final toJson = model.toJson();
      expect(toJson['id'], 'p1');
      expect(toJson['typeId'], 't1');
      expect(toJson['typeName'], 'Type1');
    });
  });
}