import '../constants/api_constants.dart';

class ImageUtils {
  static String resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }
    // Ensure single slash between base and path
    final base = ApiConstants.imageBaseUrl.endsWith('/')
        ? ApiConstants.imageBaseUrl.substring(0, ApiConstants.imageBaseUrl.length - 1)
        : ApiConstants.imageBaseUrl;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$path';
  }
}