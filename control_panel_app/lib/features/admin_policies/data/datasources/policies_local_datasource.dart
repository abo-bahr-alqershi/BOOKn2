import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/policy_model.dart';

abstract class PoliciesLocalDataSource {
  Future<void> cachePolicies(List<PolicyModel> policies);
  Future<List<PolicyModel>> getCachedPolicies();
  Future<void> cachePolicy(PolicyModel policy);
  Future<PolicyModel?> getCachedPolicy(String policyId);
  Future<void> clearCache();
}

class PoliciesLocalDataSourceImpl implements PoliciesLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const String _cachedPoliciesKey = 'CACHED_POLICIES';
  static const String _cachedPolicyPrefix = 'CACHED_POLICY_';

  PoliciesLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cachePolicies(List<PolicyModel> policies) async {
    final jsonString = jsonEncode(
      policies.map((policy) => policy.toJson()).toList(),
    );
    await sharedPreferences.setString(_cachedPoliciesKey, jsonString);
  }

  @override
  Future<List<PolicyModel>> getCachedPolicies() async {
    final jsonString = sharedPreferences.getString(_cachedPoliciesKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => PolicyModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> cachePolicy(PolicyModel policy) async {
    final jsonString = jsonEncode(policy.toJson());
    await sharedPreferences.setString(
      '$_cachedPolicyPrefix${policy.id}',
      jsonString,
    );
  }

  @override
  Future<PolicyModel?> getCachedPolicy(String policyId) async {
    final jsonString = sharedPreferences.getString('$_cachedPolicyPrefix$policyId');
    if (jsonString != null) {
      return PolicyModel.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(_cachedPoliciesKey);
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachedPolicyPrefix)) {
        await sharedPreferences.remove(key);
      }
    }
  }
}
