// lib/core/constants/section_constants.dart

class SectionConstants {
  SectionConstants._();

  // Section Type Keys (matching backend)
  static const String singlePropertyAd = 'SINGLE_PROPERTY_AD';
  static const String multiPropertyAd = 'MULTI_PROPERTY_AD';
  static const String unitShowcaseAd = 'UNIT_SHOWCASE_AD';
  
  static const String singlePropertyOffer = 'SINGLE_PROPERTY_OFFER';
  static const String limitedTimeOffer = 'LIMITED_TIME_OFFER';
  static const String seasonalOffer = 'SEASONAL_OFFER';
  static const String multiPropertyOffersGrid = 'MULTI_PROPERTY_OFFERS_GRID';
  static const String offersCarousel = 'OFFERS_CAROUSEL';
  static const String flashDeals = 'FLASH_DEALS';
  
  static const String horizontalPropertyList = 'HORIZONTAL_PROPERTY_LIST';
  static const String verticalPropertyGrid = 'VERTICAL_PROPERTY_GRID';
  static const String mixedLayoutList = 'MIXED_LAYOUT_LIST';
  static const String compactPropertyList = 'COMPACT_PROPERTY_LIST';
  
  static const String cityCardsGrid = 'CITY_CARDS_GRID';
  static const String destinationCarousel = 'DESTINATION_CAROUSEL';
  static const String exploreCities = 'EXPLORE_CITIES';
  
  static const String premiumCarousel = 'PREMIUM_CAROUSEL';
  static const String interactiveShowcase = 'INTERACTIVE_SHOWCASE';
  
  // Section Categories
  static const String sponsoredCategory = 'SPONSORED';
  static const String offersCategory = 'OFFERS';
  static const String listingsCategory = 'LISTINGS';
  static const String destinationsCategory = 'DESTINATIONS';
  static const String carouselsCategory = 'CAROUSELS';
  
  // Configuration Keys
  static const String titleKey = 'title';
  static const String subtitleKey = 'subtitle';
  static const String backgroundColorKey = 'backgroundColor';
  static const String textColorKey = 'textColor';
  static const String customImageKey = 'customImage';
  static const String propertyIdsKey = 'propertyIds';
  static const String cityIdsKey = 'cityIds';
  static const String maxItemsKey = 'maxItems';
  static const String autoPlayKey = 'autoPlay';
  static const String autoPlayDurationKey = 'autoPlayDuration';
  static const String showIndicatorsKey = 'showIndicators';
  static const String parallaxEnabledKey = 'parallaxEnabled';
  static const String animationTypeKey = 'animationType';
  static const String layoutTypeKey = 'layoutType';
  static const String filterKey = 'filter';
  static const String sortByKey = 'sortBy';
  static const String showBadgeKey = 'showBadge';
  static const String badgeTextKey = 'badgeText';
  static const String badgeColorKey = 'badgeColor';
  static const String ctaTextKey = 'ctaText';
  static const String ctaActionKey = 'ctaAction';
  static const String discountPercentageKey = 'discountPercentage';
  static const String expiryDateKey = 'expiryDate';
  static const String themeKey = 'theme';
  
  // Default Values
  static const int defaultMaxItems = 10;
  static const bool defaultAutoPlay = true;
  static const int defaultAutoPlayDuration = 5; // seconds
  static const bool defaultShowIndicators = true;
  static const bool defaultParallaxEnabled = false;
  static const String defaultAnimationType = 'fade';
  static const String defaultLayoutType = 'standard';
  
  // Sort Options
  static const String sortByPrice = 'price';
  static const String sortByRating = 'rating';
  static const String sortByDistance = 'distance';
  static const String sortByPopularity = 'popularity';
  static const String sortByNewest = 'newest';
}