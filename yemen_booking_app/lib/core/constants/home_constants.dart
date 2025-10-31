// lib/core/constants/home_constants.dart

class HomeConstants {
  HomeConstants._();

  // Cache durations
  static const Duration homeCacheDuration = Duration(hours: 2);
  static const Duration sectionCacheDuration = Duration(hours: 1);
  static const Duration imageCacheDuration = Duration(days: 7);
  
  // Performance settings
  static const int maxSectionsPerPage = 10;
  static const int lazyLoadThreshold = 3;
  static const int imageQuality = 85;
  
  // Refresh settings
  static const Duration refreshThrottle = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  // Analytics
  static const Duration impressionDuration = Duration(seconds: 2);
  static const double visibilityThreshold = 0.5; // 50% visible
  
  // Section Heights
  static const double singlePropertyAdHeight = 320.0;
  static const double multiPropertyAdHeight = 280.0;
  static const double unitShowcaseAdHeight = 450.0;
  
  static const double singleOfferHeight = 200.0;
  static const double limitedTimeOfferHeight = 220.0;
  static const double seasonalOfferHeight = 240.0;
  static const double offersGridHeight = 400.0;
  static const double offersCarouselHeight = 260.0;
  static const double flashDealsHeight = 280.0;
  
  static const double horizontalListHeight = 280.0;
  static const double verticalGridMinHeight = 400.0;
  static const double mixedLayoutHeight = 500.0;
  static const double compactListHeight = 180.0;
  
  static const double cityCardsHeight = 200.0;
  static const double destinationCarouselHeight = 240.0;
  static const double exploreCitiesHeight = 320.0;
  
  static const double premiumCarouselHeight = 380.0;
  static const double interactiveCarouselHeight = 420.0;
  
  // Spacing
  static const double sectionSpacing = 24.0;
  static const double itemSpacing = 16.0;
  static const double smallSpacing = 8.0;
  
  // Border Radius
  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 16.0;
  static const double circularRadius = 999.0;
  
  // Shadow
  static const double defaultElevation = 4.0;
  static const double highElevation = 8.0;
  
  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // Carousel Settings
  static const double carouselViewportFraction = 0.85;
  static const double carouselAspectRatio = 16 / 9;
  static const Duration carouselAutoPlayDuration = Duration(seconds: 5);
  
  // Grid Settings
  static const int gridCrossAxisCount = 2;
  static const double gridAspectRatio = 0.75;
  static const double gridCrossAxisSpacing = 16.0;
  static const double gridMainAxisSpacing = 16.0;
  
  // Image Settings
  static const double imageAspectRatio = 16 / 9;
  static const double squareImageAspectRatio = 1.0;
  static const double portraitImageAspectRatio = 3 / 4;
  
  // Placeholder Settings
  static const double shimmerBaseColor = 0.05;
  static const double shimmerHighlightColor = 0.15;
  
  // Text Settings
  static const int maxTitleLines = 2;
  static const int maxDescriptionLines = 3;
  static const int maxShortDescriptionLines = 2;
}