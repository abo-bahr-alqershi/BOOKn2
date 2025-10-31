import 'package:shared_preferences/shared_preferences.dart';
import 'package:bookn_cp_app/services/local_storage_service.dart';
import 'package:bookn_cp_app/core/constants/storage_constants.dart';

/// LocalDataService placeholder after removing deleted features
class LocalDataService {
  final SharedPreferences _prefs;
  LocalDataService(this._prefs);

	bool hasCachedData() => _prefs.getKeys().isNotEmpty;
	bool isDataValid() => true;
	Map<String, dynamic> getDataStats() => {'keys': _prefs.getKeys().length};
	Future<bool> clearAllData() async => _prefs.clear();

  // Convenience getters for auth context
  String getAccountRole(LocalStorageService storage) =>
      (storage.getData(StorageConstants.accountRole) ?? '').toString();
  String getPropertyId(LocalStorageService storage) =>
      (storage.getData(StorageConstants.propertyId) ?? '').toString();
  String getPropertyName(LocalStorageService storage) =>
      (storage.getData(StorageConstants.propertyName) ?? '').toString();
  String getPropertyCurrency(LocalStorageService storage) =>
      (storage.getData(StorageConstants.propertyCurrency) ?? '').toString();
}