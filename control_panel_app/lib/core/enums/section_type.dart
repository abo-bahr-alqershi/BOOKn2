// lib/core/enums/section_ui_type.dart

/// UI Types for sections - defines which widget to use in client app
enum SectionTypeEnum {
  // Original Types
  singlePropertyAd,
  multiPropertyAd,
  unitShowcaseAd,
  singlePropertyOffer,
  limitedTimeOffer,
  seasonalOffer,
  multiPropertyOffersGrid,
  offersCarousel,
  flashDeals,
  horizontalPropertyList,
  verticalPropertyGrid,
  mixedLayoutList,
  compactPropertyList,
  cityCardsGrid,
  destinationCarousel,
  exploreCities,
  premiumCarousel,
  interactiveShowcase,

  // New Custom Display Types
  blackHoleGravityGrid,
  cosmicSinglePropertyOffer,
  dnaHelixPropertyCarousel,
  holographicHorizontalPropertyList,
  holographicSinglePropertyAd,
  liquidCrystalPropertyList,
  neuroMorphicPropertyGrid,
  quantumFlashDeals,
  auroraQuantumPortalMatrix,
  crystalConstellationNetwork,
}

extension SectionUITypeExtension on SectionTypeEnum {
  String get value {
    switch (this) {
      case SectionTypeEnum.singlePropertyAd:
        return 'singlePropertyAd';
      case SectionTypeEnum.multiPropertyAd:
        return 'multiPropertyAd';
      case SectionTypeEnum.unitShowcaseAd:
        return 'unitShowcaseAd';
      case SectionTypeEnum.singlePropertyOffer:
        return 'singlePropertyOffer';
      case SectionTypeEnum.limitedTimeOffer:
        return 'limitedTimeOffer';
      case SectionTypeEnum.seasonalOffer:
        return 'seasonalOffer';
      case SectionTypeEnum.multiPropertyOffersGrid:
        return 'multiPropertyOffersGrid';
      case SectionTypeEnum.offersCarousel:
        return 'offersCarousel';
      case SectionTypeEnum.flashDeals:
        return 'flashDeals';
      case SectionTypeEnum.horizontalPropertyList:
        return 'horizontalPropertyList';
      case SectionTypeEnum.verticalPropertyGrid:
        return 'verticalPropertyGrid';
      case SectionTypeEnum.mixedLayoutList:
        return 'mixedLayoutList';
      case SectionTypeEnum.compactPropertyList:
        return 'compactPropertyList';
      case SectionTypeEnum.cityCardsGrid:
        return 'cityCardsGrid';
      case SectionTypeEnum.destinationCarousel:
        return 'destinationCarousel';
      case SectionTypeEnum.exploreCities:
        return 'exploreCities';
      case SectionTypeEnum.premiumCarousel:
        return 'premiumCarousel';
      case SectionTypeEnum.interactiveShowcase:
        return 'interactiveShowcase';
      // Custom Display Types
      case SectionTypeEnum.blackHoleGravityGrid:
        return 'blackHoleGravityGrid';
      case SectionTypeEnum.cosmicSinglePropertyOffer:
        return 'cosmicSinglePropertyOffer';
      case SectionTypeEnum.dnaHelixPropertyCarousel:
        return 'dnaHelixPropertyCarousel';
      case SectionTypeEnum.holographicHorizontalPropertyList:
        return 'holographicHorizontalPropertyList';
      case SectionTypeEnum.holographicSinglePropertyAd:
        return 'holographicSinglePropertyAd';
      case SectionTypeEnum.liquidCrystalPropertyList:
        return 'liquidCrystalPropertyList';
      case SectionTypeEnum.neuroMorphicPropertyGrid:
        return 'neuroMorphicPropertyGrid';
      case SectionTypeEnum.quantumFlashDeals:
        return 'quantumFlashDeals';
      case SectionTypeEnum.auroraQuantumPortalMatrix:
        return 'auroraQuantumPortalMatrix';
      case SectionTypeEnum.crystalConstellationNetwork:
        return 'crystalConstellationNetwork';
    }
  }

  String get displayName {
    switch (this) {
      case SectionTypeEnum.singlePropertyAd:
        return 'إعلان عقار واحد';
      case SectionTypeEnum.multiPropertyAd:
        return 'إعلان عقارات متعددة';
      case SectionTypeEnum.unitShowcaseAd:
        return 'عرض الوحدات';
      case SectionTypeEnum.singlePropertyOffer:
        return 'عرض عقار واحد';
      case SectionTypeEnum.limitedTimeOffer:
        return 'عرض محدود الوقت';
      case SectionTypeEnum.seasonalOffer:
        return 'عرض موسمي';
      case SectionTypeEnum.multiPropertyOffersGrid:
        return 'شبكة عروض متعددة';
      case SectionTypeEnum.offersCarousel:
        return 'عروض دوارة';
      case SectionTypeEnum.flashDeals:
        return 'عروض سريعة';
      case SectionTypeEnum.horizontalPropertyList:
        return 'قائمة أفقية';
      case SectionTypeEnum.verticalPropertyGrid:
        return 'شبكة عمودية';
      case SectionTypeEnum.mixedLayoutList:
        return 'قائمة مختلطة';
      case SectionTypeEnum.compactPropertyList:
        return 'قائمة مضغوطة';
      case SectionTypeEnum.cityCardsGrid:
        return 'شبكة بطاقات المدن';
      case SectionTypeEnum.destinationCarousel:
        return 'دوار الوجهات';
      case SectionTypeEnum.exploreCities:
        return 'استكشف المدن';
      case SectionTypeEnum.premiumCarousel:
        return 'العرض المميز';
      case SectionTypeEnum.interactiveShowcase:
        return 'عرض تفاعلي';
      // Custom Display Types
      case SectionTypeEnum.blackHoleGravityGrid:
        return '🌌 شبكة الثقب الأسود';
      case SectionTypeEnum.cosmicSinglePropertyOffer:
        return '✨ العرض الكوني';
      case SectionTypeEnum.dnaHelixPropertyCarousel:
        return '🧬 عرض الحلزون المزدوج';
      case SectionTypeEnum.holographicHorizontalPropertyList:
        return '📱 قائمة ثلاثية الأبعاد';
      case SectionTypeEnum.holographicSinglePropertyAd:
        return '🎭 إعلان هولوجرامي';
      case SectionTypeEnum.liquidCrystalPropertyList:
        return '💎 عرض الكريستال السائل';
      case SectionTypeEnum.neuroMorphicPropertyGrid:
        return '🧠 الشبكة العصبية';
      case SectionTypeEnum.quantumFlashDeals:
        return '⚡ عروض كمومية سريعة';
      case SectionTypeEnum.auroraQuantumPortalMatrix:
        return '🌈 بوابة الشفق الكمومي';
      case SectionTypeEnum.crystalConstellationNetwork:
        return '💠 شبكة الأبراج البلورية';
    }
  }

  static SectionTypeEnum? tryFromString(String? value) {
    if (value == null) return null;
    for (final type in SectionTypeEnum.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}
