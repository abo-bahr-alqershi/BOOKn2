import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yemen_booking_app/features/home/data/models/property_type_model.dart';
import 'package:yemen_booking_app/features/home/data/models/unit_type_model.dart';
import 'package:yemen_booking_app/features/search/data/models/search_filter_model.dart';

/// خدمة إدارة البيانات المحلية لأنواع العقارات والوحدات والحقول الديناميكية
class LocalDataService {
  static const String _propertyTypesKey = 'cached_property_types';
  static const String _unitTypesKey = 'cached_unit_types';
  static const String _dynamicFieldsKey = 'cached_dynamic_fields';
  static const String _lastSyncKey = 'last_data_sync';
  static const String _dataVersionKey = 'data_version';

  final SharedPreferences _prefs;

  LocalDataService(this._prefs);

  /// حفظ أنواع العقارات محلياً
  Future<bool> savePropertyTypes(List<PropertyTypeModel> propertyTypes) async {
    try {
      final jsonList = propertyTypes.map((pt) => pt.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await _prefs.setString(_propertyTypesKey, jsonString);
      await _updateLastSync();
      await _incrementDataVersion();
      
      return true;
    } catch (e) {
      print('Error saving property types: $e');
      return false;
    }
  }

  /// جلب أنواع العقارات المحفوظة محلياً
  List<PropertyTypeModel> getPropertyTypes() {
    try {
      final jsonString = _prefs.getString(_propertyTypesKey);
      if (jsonString == null) return [];

      final jsonList = json.decode(jsonString) as List;
      return jsonList
          .map((json) => PropertyTypeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading property types: $e');
      return [];
    }
  }

  /// حفظ أنواع الوحدات محلياً
  Future<bool> saveUnitTypes(List<UnitTypeModel> unitTypes) async {
    try {
      final jsonList = unitTypes.map((ut) => ut.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await _prefs.setString(_unitTypesKey, jsonString);
      await _updateLastSync();
      await _incrementDataVersion();
      
      return true;
    } catch (e) {
      print('Error saving unit types: $e');
      return false;
    }
  }

  /// جلب أنواع الوحدات المحفوظة محلياً
  List<UnitTypeModel> getUnitTypes() {
    try {
      final jsonString = _prefs.getString(_unitTypesKey);
      if (jsonString == null) return [];

      final jsonList = json.decode(jsonString) as List;
      return jsonList
          .map((json) => UnitTypeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading unit types: $e');
      return [];
    }
  }

  /// جلب أنواع الوحدات حسب نوع العقار
  List<UnitTypeModel> getUnitTypesByPropertyType(String propertyTypeId) {
    final allUnitTypes = getUnitTypes();
    return allUnitTypes
        .where((unitType) => unitType.propertyTypeId == propertyTypeId)
        .toList();
  }

  /// حفظ الحقول الديناميكية محلياً
  Future<bool> saveDynamicFields(List<UnitTypeFieldModel> fields) async {
    try {
      final jsonList = fields.map((field) => field.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await _prefs.setString(_dynamicFieldsKey, jsonString);
      await _updateLastSync();
      await _incrementDataVersion();
      
      return true;
    } catch (e) {
      print('Error saving dynamic fields: $e');
      return false;
    }
  }

  /// جلب الحقول الديناميكية المحفوظة محلياً
  List<UnitTypeFieldModel> getDynamicFields() {
    try {
      final jsonString = _prefs.getString(_dynamicFieldsKey);
      if (jsonString == null) return [];

      final jsonList = json.decode(jsonString) as List;
      return jsonList
          .map((json) => UnitTypeFieldModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading dynamic fields: $e');
      return [];
    }
  }

  /// جلب الحقول الديناميكية حسب نوع الوحدة
  List<UnitTypeFieldModel> getDynamicFieldsByUnitType(String unitTypeId) {
    final allFields = getDynamicFields();
    return allFields
        .where((field) => field.unitTypeId == unitTypeId)
        .toList();
  }

  /// جلب الحقول الديناميكية القابلة للفلترة حسب نوع الوحدة
  List<UnitTypeFieldModel> getFilterableFieldsByUnitType(String unitTypeId) {
    final allFields = getDynamicFields();
    return allFields
        .where((field) => 
            field.unitTypeId == unitTypeId && 
            field.isSearchable && 
            field.isPublic)
        .toList();
  }

  /// حفظ جميع البيانات دفعة واحدة
  Future<bool> saveAllData({
    required List<PropertyTypeModel> propertyTypes,
    required List<UnitTypeModel> unitTypes,
    required List<UnitTypeFieldModel> dynamicFields,
  }) async {
    try {
      await Future.wait([
        savePropertyTypes(propertyTypes),
        saveUnitTypes(unitTypes),
        saveDynamicFields(dynamicFields),
      ]);
      
      await _updateLastSync();
      await _incrementDataVersion();
      
      return true;
    } catch (e) {
      print('Error saving all data: $e');
      return false;
    }
  }

  /// التحقق من وجود بيانات محفوظة
  bool hasCachedData() {
    return _prefs.containsKey(_propertyTypesKey) &&
           _prefs.containsKey(_unitTypesKey) &&
           _prefs.containsKey(_dynamicFieldsKey);
  }

  /// جلب وقت آخر مزامنة
  DateTime? getLastSyncTime() {
    final timeString = _prefs.getString(_lastSyncKey);
    if (timeString != null) {
      return DateTime.tryParse(timeString);
    }
    return null;
  }

  /// جلب إصدار البيانات
  int getDataVersion() {
    return _prefs.getInt(_dataVersionKey) ?? 0;
  }

  /// مسح جميع البيانات المحفوظة
  Future<bool> clearAllData() async {
    try {
      await Future.wait([
        _prefs.remove(_propertyTypesKey),
        _prefs.remove(_unitTypesKey),
        _prefs.remove(_dynamicFieldsKey),
        _prefs.remove(_lastSyncKey),
        _prefs.remove(_dataVersionKey),
      ]);
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }

  /// التحقق من صلاحية البيانات المحفوظة (أقل من 24 ساعة)
  bool isDataValid() {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    // البيانات صالحة لمدة 24 ساعة
    return difference.inHours < 24;
  }

  /// جلب إحصائيات البيانات المحفوظة
  Map<String, dynamic> getDataStats() {
    final propertyTypes = getPropertyTypes();
    final unitTypes = getUnitTypes();
    final dynamicFields = getDynamicFields();
    final lastSync = getLastSyncTime();
    final dataVersion = getDataVersion();

    return {
      'propertyTypesCount': propertyTypes.length,
      'unitTypesCount': unitTypes.length,
      'dynamicFieldsCount': dynamicFields.length,
      'lastSyncTime': lastSync?.toIso8601String(),
      'dataVersion': dataVersion,
      'isDataValid': isDataValid(),
      'hasCachedData': hasCachedData(),
    };
  }

  // Private methods
  Future<void> _updateLastSync() async {
    await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  Future<void> _incrementDataVersion() async {
    final currentVersion = getDataVersion();
    await _prefs.setInt(_dataVersionKey, currentVersion + 1);
  }
}