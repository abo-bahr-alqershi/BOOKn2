// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Yemen Booking';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Durations
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceTime = Duration(milliseconds: 500);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Image Limits
  static const int maxImageUploadSize = 10 * 1024 * 1024; // 10MB
  static const int maxImagesPerProperty = 20;
  static const int maxReviewImages = 5;

  // Video Limits
  static const int maxVideoUploadSize = 100 * 1024 * 1024; // 100MB
  static const int maxVideosPerProperty = 5;
  static const Duration maxVideoDuration = Duration(minutes: 5);
  static const int minVideoDuration = 1; // seconds

  // Supported Media Formats
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];
  static const List<String> supportedVideoFormats = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm'
  ];

  // Media Types
  static const String imageMediaType = 'image';
  static const String videoMediaType = 'video';

  // Password
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int otpLength = 6;

  // Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String currencyCode = 'YER';
  static const String currencySymbol = '﷼';

  // Map
  static const double defaultLatitude = 15.3694;
  static const double defaultLongitude = 44.1910;
  static const double defaultZoom = 12.0;

  // Cache
  static const Duration cacheValidDuration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Regex Patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+?967[0-9]{9}$';
  static const String namePattern = r'^[a-zA-Z\u0600-\u06FF\s]+$';

  // Helper Methods
  static bool isVideoFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return supportedVideoFormats.contains(extension);
  }

  static bool isImageFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return supportedImageFormats.contains(extension);
  }

  static String getMediaType(String filePath) {
    if (isVideoFile(filePath)) return videoMediaType;
    if (isImageFile(filePath)) return imageMediaType;
    return imageMediaType; // default
  }
}
