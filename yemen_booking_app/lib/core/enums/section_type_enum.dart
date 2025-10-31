// lib/core/enums/section_type_enum.dart

enum SectionType {
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
  // Custom Display Types
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

extension SectionTypeExtension on SectionType {
  String get value {
    switch (this) {
      case SectionType.singlePropertyAd:
        return 'singlePropertyAd';
      case SectionType.multiPropertyAd:
        return 'multiPropertyAd';
      case SectionType.unitShowcaseAd:
        return 'unitShowcaseAd';
      case SectionType.singlePropertyOffer:
        return 'singlePropertyOffer';
      case SectionType.limitedTimeOffer:
        return 'limitedTimeOffer';
      case SectionType.seasonalOffer:
        return 'seasonalOffer';
      case SectionType.multiPropertyOffersGrid:
        return 'multiPropertyOffersGrid';
      case SectionType.offersCarousel:
        return 'offersCarousel';
      case SectionType.flashDeals:
        return 'flashDeals';
      case SectionType.horizontalPropertyList:
        return 'horizontalPropertyList';
      case SectionType.verticalPropertyGrid:
        return 'verticalPropertyGrid';
      case SectionType.mixedLayoutList:
        return 'mixedLayoutList';
      case SectionType.compactPropertyList:
        return 'compactPropertyList';
      case SectionType.cityCardsGrid:
        return 'cityCardsGrid';
      case SectionType.destinationCarousel:
        return 'destinationCarousel';
      case SectionType.exploreCities:
        return 'exploreCities';
      case SectionType.premiumCarousel:
        return 'premiumCarousel';
      case SectionType.interactiveShowcase:
        return 'interactiveShowcase';
      // Custom Display Types
      case SectionType.blackHoleGravityGrid:
        return 'blackHoleGravityGrid';
      case SectionType.cosmicSinglePropertyOffer:
        return 'cosmicSinglePropertyOffer';
      case SectionType.dnaHelixPropertyCarousel:
        return 'dnaHelixPropertyCarousel';
      case SectionType.holographicHorizontalPropertyList:
        return 'holographicHorizontalPropertyList';
      case SectionType.holographicSinglePropertyAd:
        return 'holographicSinglePropertyAd';
      case SectionType.liquidCrystalPropertyList:
        return 'liquidCrystalPropertyList';
      case SectionType.neuroMorphicPropertyGrid:
        return 'neuroMorphicPropertyGrid';
      case SectionType.quantumFlashDeals:
        return 'quantumFlashDeals';
      case SectionType.auroraQuantumPortalMatrix:
        return 'auroraQuantumPortalMatrix';
      case SectionType.crystalConstellationNetwork:
        return 'crystalConstellationNetwork';
    }
  }

  static SectionType? tryFromString(String value) {
    for (final type in SectionType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}