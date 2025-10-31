import 'package:yemen_booking_app/services/local_data_service.dart';
import 'package:yemen_booking_app/services/connectivity_service.dart';
import 'package:yemen_booking_app/features/home/data/models/property_type_model.dart';
import 'package:yemen_booking_app/features/home/data/models/unit_type_model.dart';
import 'package:yemen_booking_app/features/search/data/models/search_filter_model.dart';
import 'package:yemen_booking_app/features/reference/data/datasources/reference_remote_datasource.dart';
import 'package:yemen_booking_app/features/reference/data/models/city_model.dart';
import 'package:yemen_booking_app/features/reference/data/models/currency_model.dart';
import 'package:yemen_booking_app/features/home/data/datasources/home_remote_datasource.dart';

/// خدمة مزامنة البيانات - تجمع بين البيانات المحلية والباك اند
class DataSyncService {
  final LocalDataService _localDataService;
  final ConnectivityService _connectivityService;
  final HomeRemoteDataSource _remoteDataSource;
  final ReferenceRemoteDataSource _referenceRemoteDataSource;

  DataSyncService({
    required LocalDataService localDataService,
    required ConnectivityService connectivityService,
    required HomeRemoteDataSource remoteDataSource,
    required ReferenceRemoteDataSource referenceRemoteDataSource,
  })  : _localDataService = localDataService,
        _connectivityService = connectivityService,
        _remoteDataSource = remoteDataSource,
        _referenceRemoteDataSource = referenceRemoteDataSource;

  /// جلب أنواع العقارات مع دعم الحفظ المحلي
  Future<List<PropertyTypeModel>> getPropertyTypes() async {
    try {
      // التحقق من الاتصال
      final isConnected = await _connectivityService.checkConnection();
      
      if (isConnected) {
        // جلب من الباك اند
        final remoteData = await _remoteDataSource.getPropertyTypes();
        
        // حفظ محلياً
        await _localDataService.savePropertyTypes(remoteData);
        
        return remoteData;
      } else {
        // استخدام البيانات المحفوظة
        final localData = _localDataService.getPropertyTypes();
        
        if (localData.isNotEmpty) {
          return localData;
        } else {
          throw Exception('لا توجد بيانات محفوظة محلياً');
        }
      }
    } catch (e) {
      // في حالة الخطأ، محاولة استخدام البيانات المحفوظة
      final localData = _localDataService.getPropertyTypes();
      if (localData.isNotEmpty) {
        return localData;
      }
      rethrow;
    }
  }

  /// جلب أنواع الوحدات حسب نوع العقار مع دعم الحفظ المحلي
  Future<List<UnitTypeModel>> getUnitTypes({required String propertyTypeId}) async {
    try {
      // التحقق من الاتصال
      final isConnected = await _connectivityService.checkConnection();
      
      if (isConnected) {
        // جلب من الباك اند
        final remoteData = await _remoteDataSource.getUnitTypes(propertyTypeId: propertyTypeId);
        
        // حفظ محلياً
        await _localDataService.saveUnitTypes(remoteData);
        
        return remoteData;
      } else {
        // استخدام البيانات المحفوظة
        final localData = _localDataService.getUnitTypesByPropertyType(propertyTypeId);
        
        if (localData.isNotEmpty) {
          return localData;
        } else {
          throw Exception('لا توجد بيانات محفوظة محلياً');
        }
      }
    } catch (e) {
      // في حالة الخطأ، محاولة استخدام البيانات المحفوظة
      final localData = _localDataService.getUnitTypesByPropertyType(propertyTypeId);
      if (localData.isNotEmpty) {
        return localData;
      }
      rethrow;
    }
  }

  /// جلب الحقول الديناميكية حسب نوع الوحدة
  Future<List<UnitTypeFieldModel>> getDynamicFieldsByUnitType(String unitTypeId) async {
    try {
      // التحقق من الاتصال
      final isConnected = await _connectivityService.checkConnection();
      
      if (isConnected) {
        // جلب من الباك اند (إذا كان متوفراً)
        // يمكن إضافة API call هنا
        final localData = _localDataService.getDynamicFieldsByUnitType(unitTypeId);
        
        if (localData.isNotEmpty) {
          return localData;
        } else {
          throw Exception('لا توجد حقول ديناميكية محفوظة');
        }
      } else {
        // استخدام البيانات المحفوظة
        final localData = _localDataService.getDynamicFieldsByUnitType(unitTypeId);
        
        if (localData.isNotEmpty) {
          return localData;
        } else {
          throw Exception('لا توجد حقول ديناميكية محفوظة محلياً');
        }
      }
    } catch (e) {
      // في حالة الخطأ، محاولة استخدام البيانات المحفوظة
      final localData = _localDataService.getDynamicFieldsByUnitType(unitTypeId);
      if (localData.isNotEmpty) {
        return localData;
      }
      rethrow;
    }
  }

  /// جلب الحقول الديناميكية القابلة للفلترة حسب نوع الوحدة
  Future<List<UnitTypeFieldModel>> getFilterableFieldsByUnitType(String unitTypeId) async {
    try {
      // التحقق من الاتصال
      final isConnected = await _connectivityService.checkConnection();
      
      if (isConnected) {
        // جلب من الباك اند (إذا كان متوفراً)
        // يمكن إضافة API call هنا
        final localData = _localDataService.getFilterableFieldsByUnitType(unitTypeId);
        
        if (localData.isNotEmpty) {
          return localData;
        } else {
          throw Exception('لا توجد حقول قابلة للفلترة محفوظة');
        }
      } else {
        // استخدام البيانات المحفوظة
        final localData = _localDataService.getFilterableFieldsByUnitType(unitTypeId);
        
        if (localData.isNotEmpty) {
          return localData;
        } else {
          throw Exception('لا توجد حقول قابلة للفلترة محفوظة محلياً');
        }
      }
    } catch (e) {
      // في حالة الخطأ، محاولة استخدام البيانات المحفوظة
      final localData = _localDataService.getFilterableFieldsByUnitType(unitTypeId);
      if (localData.isNotEmpty) {
        return localData;
      }
      rethrow;
    }
  }

  /// مزامنة جميع البيانات من الباك اند
  Future<bool> syncAllData() async {
    try {
      // التحقق من الاتصال
      final isConnected = await _connectivityService.checkConnection();
      
      if (!isConnected) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      }

      // جلب جميع البيانات من الباك اند
      final propertyTypes = await _remoteDataSource.getPropertyTypes();
      
      // جلب أنواع الوحدات لجميع أنواع العقارات
      List<UnitTypeModel> allUnitTypes = [];
      for (final propertyType in propertyTypes) {
        try {
          final unitTypes = await _remoteDataSource.getUnitTypes(
            propertyTypeId: propertyType.id,
          );
          allUnitTypes.addAll(unitTypes);
        } catch (e) {
          print('Error fetching unit types for property type ${propertyType.id}: $e');
        }
      }

      // استخراج جميع الحقول الديناميكية
      List<UnitTypeFieldModel> allDynamicFields = [];
      for (final unitType in allUnitTypes) {
        allDynamicFields.addAll(unitType.fields);
      }

      // حفظ جميع البيانات محلياً
      final success = await _localDataService.saveAllData(
        propertyTypes: propertyTypes,
        unitTypes: allUnitTypes,
        dynamicFields: allDynamicFields,
      );

      return success;
    } catch (e) {
      print('Error syncing all data: $e');
      return false;
    }
  }

  /// مزامنة البيانات المرجعية: المدن والعملات
  Future<Map<String, int>> syncReferenceData() async {
    final Map<String, int> counts = {'cities': 0, 'currencies': 0};
    try {
      final isConnected = await _connectivityService.checkConnection();
      if (!isConnected) return counts;

      final List<CityModel> cities = await _referenceRemoteDataSource.getCities();
      final List<CurrencyModel> currencies = await _referenceRemoteDataSource.getCurrencies();
      // Note: LocalDataService currently does not persist cities/currencies; apps can access via ReferenceLocalDataSource
      counts['cities'] = cities.length;
      counts['currencies'] = currencies.length;
      return counts;
    } catch (e) {
      print('Error syncing reference data: $e');
      return counts;
    }
  }

  /// مزامنة البيانات عند فتح التطبيق
  Future<void> syncOnAppStart() async {
    try {
      // التحقق من صلاحية البيانات المحفوظة
      final isDataValid = _localDataService.isDataValid();
      final hasCachedData = _localDataService.hasCachedData();
      
      // إذا لم تكن هناك بيانات محفوظة أو انتهت صلاحيتها، قم بالمزامنة
      if (!hasCachedData || !isDataValid) {
        await syncAllData();
      }
    } catch (e) {
      print('Error syncing on app start: $e');
      // لا نريد أن نوقف التطبيق إذا فشلت المزامنة
    }
  }

  /// جلب إحصائيات البيانات
  Map<String, dynamic> getDataStats() {
    return _localDataService.getDataStats();
  }

  /// مسح جميع البيانات المحفوظة
  Future<bool> clearAllData() async {
    return await _localDataService.clearAllData();
  }

  /// التحقق من وجود بيانات محفوظة
  bool hasCachedData() {
    return _localDataService.hasCachedData();
  }

  /// التحقق من صلاحية البيانات المحفوظة
  bool isDataValid() {
    return _localDataService.isDataValid();
  }
}