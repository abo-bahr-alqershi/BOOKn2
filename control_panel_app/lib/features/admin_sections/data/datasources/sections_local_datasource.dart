import 'package:shared_preferences/shared_preferences.dart';
import '../models/section_model.dart';

abstract class SectionsLocalDataSource {
  Future<void> cacheSections(List<SectionModel> sections);
  List<SectionModel> getCachedSections();
  bool isCacheFresh();
  void invalidate();
}

class SectionsLocalDataSourceImpl implements SectionsLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _kCacheKey = 'admin_sections_cache_v1';
  static const String _kCacheTimeKey = 'admin_sections_cache_time_v1';
  static const Duration _ttl = Duration(minutes: 10);

  SectionsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheSections(List<SectionModel> sections) async {
    final list = sections.map((e) => e.toJson()).toList();
    await sharedPreferences.setString(_kCacheKey, list.toString());
    await sharedPreferences.setInt(
      _kCacheTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  List<SectionModel> getCachedSections() {
    final raw = sharedPreferences.getString(_kCacheKey);
    if (raw == null || raw.isEmpty) return [];
    // Very lightweight parser for list of maps string
    try {
      final decoded = raw
          .substring(1, raw.length - 1) // strip [ ]
          .split('},')
          .map((s) => s.endsWith('}') ? s : '$s}')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => _parseMapLikeString(s))
          .map((m) => SectionModel.fromJson(m))
          .toList();
      return decoded;
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _parseMapLikeString(String s) {
    // This is a naive parser; for reliability consider using jsonEncode/jsonDecode storage instead.
    final map = <String, dynamic>{};
    final trimmed = s.startsWith('{') && s.endsWith('}') ? s.substring(1, s.length - 1) : s;
    for (final part in trimmed.split(',')) {
      final idx = part.indexOf(':');
      if (idx == -1) continue;
      final key = part.substring(0, idx).trim().replaceAll("'", '').replaceAll('"', '');
      final value = part.substring(idx + 1).trim();
      map[key] = value.replaceAll("'", '').replaceAll('"', '');
    }
    return map;
  }

  @override
  bool isCacheFresh() {
    final ts = sharedPreferences.getInt(_kCacheTimeKey);
    if (ts == null) return false;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(cachedAt) < _ttl;
  }

  @override
  void invalidate() {
    sharedPreferences.remove(_kCacheKey);
    sharedPreferences.remove(_kCacheTimeKey);
  }
}

