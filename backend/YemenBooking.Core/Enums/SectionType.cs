namespace YemenBooking.Core.Enums;

/// <summary>
/// أنواع واجهات الأقسام - يحدد أي ويدجت سيستخدم في تطبيق العميل
/// Section UI types - defines which widget to use in client app
/// </summary>
public enum SectionType
{
    // Original Types
    SinglePropertyAd = 0,
    MultiPropertyAd = 1,
    UnitShowcaseAd = 2,
    SinglePropertyOffer = 3,
    LimitedTimeOffer = 4,
    SeasonalOffer = 5,
    MultiPropertyOffersGrid = 6,
    OffersCarousel = 7,
    FlashDeals = 8,
    HorizontalPropertyList = 9,
    VerticalPropertyGrid = 10,
    MixedLayoutList = 11,
    CompactPropertyList = 12,
    CityCardsGrid = 13,
    DestinationCarousel = 14,
    ExploreCities = 15,
    PremiumCarousel = 16,
    InteractiveShowcase = 17,
    
    // New Custom Display Types
    BlackHoleGravityGrid = 18,
    CosmicSinglePropertyOffer = 19,
    DnaHelixPropertyCarousel = 20,
    HolographicHorizontalPropertyList = 21,
    HolographicSinglePropertyAd = 22,
    LiquidCrystalPropertyList = 23,
    NeuroMorphicPropertyGrid = 24,
    QuantumFlashDeals = 25,
    AuroraQuantumPortalMatrix = 26,
    CrystalConstellationNetwork = 27
}

/// <summary>
/// Extension methods for SectionType
/// </summary>
public static class SectionTypeExtensions
{
    public static string GetValue(this SectionType type)
    {
        return type switch
        {
            SectionType.SinglePropertyAd => "singlePropertyAd",
            SectionType.MultiPropertyAd => "multiPropertyAd",
            SectionType.UnitShowcaseAd => "unitShowcaseAd",
            SectionType.SinglePropertyOffer => "singlePropertyOffer",
            SectionType.LimitedTimeOffer => "limitedTimeOffer",
            SectionType.SeasonalOffer => "seasonalOffer",
            SectionType.MultiPropertyOffersGrid => "multiPropertyOffersGrid",
            SectionType.OffersCarousel => "offersCarousel",
            SectionType.FlashDeals => "flashDeals",
            SectionType.HorizontalPropertyList => "horizontalPropertyList",
            SectionType.VerticalPropertyGrid => "verticalPropertyGrid",
            SectionType.MixedLayoutList => "mixedLayoutList",
            SectionType.CompactPropertyList => "compactPropertyList",
            SectionType.CityCardsGrid => "cityCardsGrid",
            SectionType.DestinationCarousel => "destinationCarousel",
            SectionType.ExploreCities => "exploreCities",
            SectionType.PremiumCarousel => "premiumCarousel",
            SectionType.InteractiveShowcase => "interactiveShowcase",
            // Custom Display Types
            SectionType.BlackHoleGravityGrid => "blackHoleGravityGrid",
            SectionType.CosmicSinglePropertyOffer => "cosmicSinglePropertyOffer",
            SectionType.DnaHelixPropertyCarousel => "dnaHelixPropertyCarousel",
            SectionType.HolographicHorizontalPropertyList => "holographicHorizontalPropertyList",
            SectionType.HolographicSinglePropertyAd => "holographicSinglePropertyAd",
            SectionType.LiquidCrystalPropertyList => "liquidCrystalPropertyList",
            SectionType.NeuroMorphicPropertyGrid => "neuroMorphicPropertyGrid",
            SectionType.QuantumFlashDeals => "quantumFlashDeals",
            SectionType.AuroraQuantumPortalMatrix => "auroraQuantumPortalMatrix",
            SectionType.CrystalConstellationNetwork => "crystalConstellationNetwork",
            _ => type.ToString()
        };
    }
    
    public static string GetDisplayName(this SectionType type)
    {
        return type switch
        {
            SectionType.SinglePropertyAd => "إعلان عقار واحد",
            SectionType.MultiPropertyAd => "إعلان عقارات متعددة",
            SectionType.UnitShowcaseAd => "عرض الوحدات",
            SectionType.SinglePropertyOffer => "عرض عقار واحد",
            SectionType.LimitedTimeOffer => "عرض محدود الوقت",
            SectionType.SeasonalOffer => "عرض موسمي",
            SectionType.MultiPropertyOffersGrid => "شبكة عروض متعددة",
            SectionType.OffersCarousel => "عروض دوارة",
            SectionType.FlashDeals => "عروض سريعة",
            SectionType.HorizontalPropertyList => "قائمة أفقية",
            SectionType.VerticalPropertyGrid => "شبكة عمودية",
            SectionType.MixedLayoutList => "قائمة مختلطة",
            SectionType.CompactPropertyList => "قائمة مضغوطة",
            SectionType.CityCardsGrid => "شبكة بطاقات المدن",
            SectionType.DestinationCarousel => "دوار الوجهات",
            SectionType.ExploreCities => "استكشف المدن",
            SectionType.PremiumCarousel => "العرض المميز",
            SectionType.InteractiveShowcase => "عرض تفاعلي",
            // Custom Display Types
            SectionType.BlackHoleGravityGrid => "🌌 شبكة الثقب الأسود",
            SectionType.CosmicSinglePropertyOffer => "✨ العرض الكوني",
            SectionType.DnaHelixPropertyCarousel => "🧬 عرض الحلزون المزدوج",
            SectionType.HolographicHorizontalPropertyList => "📱 قائمة ثلاثية الأبعاد",
            SectionType.HolographicSinglePropertyAd => "🎭 إعلان هولوجرامي",
            SectionType.LiquidCrystalPropertyList => "💎 عرض الكريستال السائل",
            SectionType.NeuroMorphicPropertyGrid => "🧠 الشبكة العصبية",
            SectionType.QuantumFlashDeals => "⚡ عروض كمومية سريعة",
            SectionType.AuroraQuantumPortalMatrix => "🌈 بوابة الشفق الكمومي",
            SectionType.CrystalConstellationNetwork => "💠 شبكة الأبراج البلورية",
            _ => type.ToString()
        };
    }
}
