import 'package:flutter/material.dart';
import '../../../admin_users/domain/entities/user.dart';
import '../../../admin_properties/domain/entities/property.dart';
import '../../../admin_units/domain/entities/unit.dart';
import '../../../admin_cities/domain/entities/city.dart';
import '../pages/user_search_page.dart';
import '../../../admin_notifications/presentation/pages/user_selector_page.dart' as an_selector;
import '../pages/property_search_page.dart';
import '../pages/unit_search_page.dart';
import '../pages/city_search_page.dart';
import '../pages/booking_search_page.dart';

class SearchNavigationHelper {
  // البحث عن مستخدم واحد
  static Future<User?> searchSingleUser(
    BuildContext context, {
    String? initialSearchTerm,
  }) async {
    User? result;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => an_selector.AdminUserSelectorPage(
          initialSearchTerm: initialSearchTerm,
          allowMultiSelect: false,
          onUserSelected: (user) => result = user,
        ),
      ),
    );
    return result;
  }

  // البحث عن مستخدمين متعددين
  static Future<List<User>?> searchMultipleUsers(
    BuildContext context, {
    String? initialSearchTerm,
  }) async {
    List<User>? result;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => an_selector.AdminUserSelectorPage(
          initialSearchTerm: initialSearchTerm,
          allowMultiSelect: true,
          onUsersSelected: (users) => result = users,
        ),
      ),
    );
    return result;
  }

  // البحث عن عقار واحد
  static Future<Property?> searchSingleProperty(
    BuildContext context, {
    String? initialSearchTerm,
  }) async {
    Property? result;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertySearchPage(
          initialSearchTerm: initialSearchTerm,
          allowMultiSelect: false,
          onPropertySelected: (property) => result = property,
        ),
      ),
    );
    return result;
  }

  // البحث عن عقارات متعددة
  static Future<List<Property>?> searchMultipleProperties(
    BuildContext context, {
    String? initialSearchTerm,
  }) async {
    List<Property>? result;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertySearchPage(
          initialSearchTerm: initialSearchTerm,
          allowMultiSelect: true,
          onPropertiesSelected: (properties) => result = properties,
        ),
      ),
    );
    return result;
  }

  // البحث عن وحدة واحدة
  static Future<Unit?> searchSingleUnit(
    BuildContext context, {
    String? initialSearchTerm,
    String? propertyId,
  }) async {
    Unit? result;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnitSearchPage(
          initialSearchTerm: initialSearchTerm,
          propertyId: propertyId,
          allowMultiSelect: false,
          onUnitSelected: (unit) => result = unit,
        ),
      ),
    );
    return result;
  }

  // البحث عن وحدات متعددة
  static Future<List<Unit>?> searchMultipleUnits(
    BuildContext context, {
    String? initialSearchTerm,
    String? propertyId,
  }) async {
    List<Unit>? result;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnitSearchPage(
          initialSearchTerm: initialSearchTerm,
          propertyId: propertyId,
          allowMultiSelect: true,
          onUnitsSelected: (units) => result = units,
        ),
      ),
    );
    return result;
  }

  // البحث عن مدينة واحدة
  static Future<City?> searchSingleCity(
    BuildContext context, {
    String? initialSearchTerm,
    String? country,
  }) async {
    City? result;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CitySearchPage(
          initialSearchTerm: initialSearchTerm,
          country: country,
          allowMultiSelect: false,
          onCitySelected: (city) => result = city,
        ),
      ),
    );
    return result;
  }

  // البحث عن مدن متعددة
  static Future<List<City>?> searchMultipleCities(
    BuildContext context, {
    String? initialSearchTerm,
    String? country,
  }) async {
    List<City>? result;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CitySearchPage(
          initialSearchTerm: initialSearchTerm,
          country: country,
          allowMultiSelect: true,
          onCitiesSelected: (cities) => result = cities,
        ),
      ),
    );
    return result;
  }

  // البحث عن حجز واحد
  static Future<Map<String, dynamic>?> searchSingleBooking(
    BuildContext context, {
    String? initialSearchTerm,
    String? userId,
    String? unitId,
  }) async {
    Map<String, dynamic>? result;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSearchPage(
          initialSearchTerm: initialSearchTerm,
          userId: userId,
          unitId: unitId,
          allowMultiSelect: false,
          onBookingSelected: (booking) => result = booking,
        ),
      ),
    );
    return result;
  }

  // البحث عن حجوزات متعددة
  static Future<List<Map<String, dynamic>>?> searchMultipleBookings(
    BuildContext context, {
    String? initialSearchTerm,
    String? userId,
    String? unitId,
  }) async {
    List<Map<String, dynamic>>? result;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSearchPage(
          initialSearchTerm: initialSearchTerm,
          userId: userId,
          unitId: unitId,
          allowMultiSelect: true,
          onBookingsSelected: (bookings) => result = bookings,
        ),
      ),
    );
    return result;
  }
}