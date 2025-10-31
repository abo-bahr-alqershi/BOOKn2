import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FilterStorageService {
  final SharedPreferences _prefs;
  FilterStorageService(this._prefs);

  static const String _kLastPropertyTypeId = 'filter_last_property_type_id';
  static const String _kLastUnitTypeId = 'filter_last_unit_type_id';
  static const String _kCheckIn = 'filter_check_in';
  static const String _kCheckOut = 'filter_check_out';
  static const String _kAdults = 'filter_adults';
  static const String _kChildren = 'filter_children';
  static const String _kDynamicFieldFilters = 'filter_dynamic_field_filters';
  static const String _kCurrentFilters = 'filter_current_filters';
  static const String _kCity = 'filter_city';
  static const String _kSearchTerm = 'filter_search_term';

  Future<void> saveHomeSelections({
    String? propertyTypeId,
    String? unitTypeId,
    required Map<String, dynamic> dynamicFieldValues,
  }) async {
    if (propertyTypeId != null) {
      await _prefs.setString(_kLastPropertyTypeId, propertyTypeId);
    }
    if (unitTypeId != null) {
      await _prefs.setString(_kLastUnitTypeId, unitTypeId);
    }

    final DateTime? checkIn = dynamicFieldValues['checkIn'] is DateTime
        ? dynamicFieldValues['checkIn'] as DateTime
        : null;
    final DateTime? checkOut = dynamicFieldValues['checkOut'] is DateTime
        ? dynamicFieldValues['checkOut'] as DateTime
        : null;
    final int adults = (dynamicFieldValues['adults'] as int?) ?? 0;
    final int children = (dynamicFieldValues['children'] as int?) ?? 0;

    if (checkIn != null) {
      await _prefs.setString(_kCheckIn, checkIn.toIso8601String());
    } else {
      await _prefs.remove(_kCheckIn);
    }
    if (checkOut != null) {
      await _prefs.setString(_kCheckOut, checkOut.toIso8601String());
    } else {
      await _prefs.remove(_kCheckOut);
    }
    await _prefs.setInt(_kAdults, adults);
    await _prefs.setInt(_kChildren, children);

    final dynamicFilters = Map<String, dynamic>.from(dynamicFieldValues)
      ..removeWhere((k, v) => {'checkIn', 'checkOut', 'adults', 'children'}.contains(k));
    await _prefs.setString(_kDynamicFieldFilters, jsonEncode(dynamicFilters));
  }

  Map<String, dynamic> getHomeSelections() {
    final map = <String, dynamic>{};

    final pt = _prefs.getString(_kLastPropertyTypeId);
    final ut = _prefs.getString(_kLastUnitTypeId);
    if (pt != null) map['propertyTypeId'] = pt;
    if (ut != null) map['unitTypeId'] = ut;

    final checkInStr = _prefs.getString(_kCheckIn);
    final checkOutStr = _prefs.getString(_kCheckOut);
    if (checkInStr != null) map['checkIn'] = DateTime.tryParse(checkInStr);
    if (checkOutStr != null) map['checkOut'] = DateTime.tryParse(checkOutStr);

    final adults = _prefs.getInt(_kAdults) ?? 0;
    final children = _prefs.getInt(_kChildren) ?? 0;
    map['adults'] = adults;
    map['children'] = children;

    final dynamicFiltersJson = _prefs.getString(_kDynamicFieldFilters);
    Map<String, dynamic> dynamicFilters = {};
    if (dynamicFiltersJson != null) {
      try {
        dynamicFilters = Map<String, dynamic>.from(jsonDecode(dynamicFiltersJson));
      } catch (_) {}
    }
    map['dynamicFieldFilters'] = dynamicFilters;

    final dynamicFieldValuesCombined = {
      ...dynamicFilters,
      if (map['checkIn'] != null) 'checkIn': map['checkIn'],
      if (map['checkOut'] != null) 'checkOut': map['checkOut'],
      'adults': adults,
      'children': children,
    };
    map['dynamicFieldValues'] = dynamicFieldValuesCombined;

    final city = _prefs.getString(_kCity);
    final searchTerm = _prefs.getString(_kSearchTerm);
    if (city != null) map['city'] = city;
    if (searchTerm != null) map['searchTerm'] = searchTerm;

    return map;
  }

  Future<void> saveCurrentFilters(Map<String, dynamic> filters) async {
    final f = Map<String, dynamic>.from(filters);
    if (f['checkIn'] is DateTime) {
      f['checkIn'] = (f['checkIn'] as DateTime).toIso8601String();
    }
    if (f['checkOut'] is DateTime) {
      f['checkOut'] = (f['checkOut'] as DateTime).toIso8601String();
    }
    await _prefs.setString(_kCurrentFilters, jsonEncode(f));

    if (f['propertyTypeId'] is String) {
      await _prefs.setString(_kLastPropertyTypeId, f['propertyTypeId']);
    }
    if (f['unitTypeId'] is String) {
      await _prefs.setString(_kLastUnitTypeId, f['unitTypeId']);
    }
    if (f['city'] is String) {
      await _prefs.setString(_kCity, f['city']);
    }
    if (f['searchTerm'] is String) {
      await _prefs.setString(_kSearchTerm, f['searchTerm']);
    }
  }

  Map<String, dynamic>? getCurrentFilters() {
    final jsonStr = _prefs.getString(_kCurrentFilters);
    if (jsonStr == null) return null;
    try {
      final m = Map<String, dynamic>.from(jsonDecode(jsonStr));
      if (m['checkIn'] is String) {
        m['checkIn'] = DateTime.tryParse(m['checkIn']);
      }
      if (m['checkOut'] is String) {
        m['checkOut'] = DateTime.tryParse(m['checkOut']);
      }
      return m;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSelections() async {
    await _prefs.remove(_kLastPropertyTypeId);
    await _prefs.remove(_kLastUnitTypeId);
    await _prefs.remove(_kCheckIn);
    await _prefs.remove(_kCheckOut);
    await _prefs.remove(_kAdults);
    await _prefs.remove(_kChildren);
    await _prefs.remove(_kDynamicFieldFilters);
  }

  Future<void> clearCurrentFilters() async {
    await _prefs.remove(_kCurrentFilters);
  }
}
