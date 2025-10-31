import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/api_constants.dart';

class ImageUtils {
  static String resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      // If running on web over HTTPS, avoid mixed content by upgrading scheme when same host
      if (kIsWeb) {
        try {
          final currentOrigin = Uri.base.origin; // e.g., https://host[:port]
          final u = Uri.parse(trimmed);
          final originUri = Uri.parse(currentOrigin);
          if (u.scheme == 'http' && originUri.scheme == 'https' && u.host == originUri.host && u.port == originUri.port) {
            return u.replace(scheme: 'https').toString();
          }
        } catch (_) {}
      }
      return trimmed;
    }
    // For relative paths:
    // - If it starts with '/api/', prefer ApiConstants.baseUrl (same domain as API, may require auth headers elsewhere)
    // - Otherwise, use imageBaseUrl for static/media paths
    final bool isApiPath = trimmed.startsWith('/api/');
    final String base = kIsWeb
        ? Uri.base.origin // match the app's origin to avoid mixed-content on web
        : (() {
            final src = isApiPath ? ApiConstants.baseUrl : ApiConstants.imageBaseUrl;
            return src.endsWith('/') ? src.substring(0, src.length - 1) : src;
          })();
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$path';
  }

  static String resolveApiUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      if (kIsWeb) {
        try {
          final currentOrigin = Uri.base.origin;
          final u = Uri.parse(trimmed);
          final originUri = Uri.parse(currentOrigin);
          if (u.scheme == 'http' && originUri.scheme == 'https' && u.host == originUri.host && u.port == originUri.port) {
            return u.replace(scheme: 'https').toString();
          }
        } catch (_) {}
      }
      return trimmed;
    }
    final String base = kIsWeb
        ? Uri.base.origin
        : (ApiConstants.baseUrl.endsWith('/')
            ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
            : ApiConstants.baseUrl);
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$path';
  }
}