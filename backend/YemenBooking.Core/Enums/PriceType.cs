namespace YemenBooking.Core.Enums;

/// <summary>
/// تعداد أنواع التسعير
/// Price Type enumeration
/// </summary>
public static class PriceType
{
    /// <summary>
    /// السعر الأساسي
    /// Base Price
    /// </summary>
    public const string Base = "Base";
    
    /// <summary>
    /// سعر نهاية الأسبوع
    /// Weekend Price
    /// </summary>
    public const string Weekend = "Weekend";
    
    /// <summary>
    /// سعر الموسم
    /// Seasonal Price
    /// </summary>
    public const string Seasonal = "Seasonal";
    
    /// <summary>
    /// سعر العطلة
    /// Holiday Price
    /// </summary>
    public const string Holiday = "Holiday";
    
    /// <summary>
    /// سعر خاص
    /// Special Price
    /// </summary>
    public const string Special = "Special";
    
    /// <summary>
    /// سعر الذروة
    /// Peak Price
    /// </summary>
    public const string Peak = "Peak";
    
    /// <summary>
    /// سعر الركود
    /// Off-Peak Price
    /// </summary>
    public const string OffPeak = "OffPeak";
    
    /// <summary>
    /// خصم الحجز المبكر
    /// Early Bird Discount
    /// </summary>
    public const string EarlyBird = "EarlyBird";
    
    /// <summary>
    /// خصم اللحظة الأخيرة
    /// Last Minute Discount
    /// </summary>
    public const string LastMinute = "LastMinute";
    
    /// <summary>
    /// التحقق من صحة نوع السعر
    /// Validate price type value
    /// </summary>
    public static bool IsValidPriceType(string priceType)
    {
        return priceType == Base || 
               priceType == Weekend || 
               priceType == Seasonal || 
               priceType == Holiday || 
               priceType == Special ||
               priceType == Peak ||
               priceType == OffPeak ||
               priceType == EarlyBird ||
               priceType == LastMinute;
    }
    
    /// <summary>
    /// الحصول على جميع أنواع الأسعار
    /// Get all price types
    /// </summary>
    public static string[] GetAllPriceTypes()
    {
        return new[] { Base, Weekend, Seasonal, Holiday, Special, Peak, OffPeak, EarlyBird, LastMinute };
    }
}

/// <summary>
/// تعداد فئات التسعير
/// Pricing Tier enumeration
/// </summary>
public static class PricingTier
{
    /// <summary>
    /// الفئة الأساسية
    /// Standard Tier
    /// </summary>
    public const string Standard = "Standard";
    
    /// <summary>
    /// الفئة المتميزة
    /// Premium Tier
    /// </summary>
    public const string Premium = "Premium";
    
    /// <summary>
    /// الفئة الفاخرة
    /// Luxury Tier
    /// </summary>
    public const string Luxury = "Luxury";
    
    /// <summary>
    /// الفئة الاقتصادية
    /// Economy Tier
    /// </summary>
    public const string Economy = "Economy";
    
    /// <summary>
    /// التحقق من صحة فئة التسعير
    /// Validate pricing tier value
    /// </summary>
    public static bool IsValidTier(string tier)
    {
        return tier == Standard || 
               tier == Premium || 
               tier == Luxury || 
               tier == Economy;
    }
    
    /// <summary>
    /// الحصول على جميع فئات التسعير
    /// Get all pricing tiers
    /// </summary>
    public static string[] GetAllTiers()
    {
        return new[] { Standard, Premium, Luxury, Economy };
    }
}
