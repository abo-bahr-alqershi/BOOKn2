using System;
using System.Collections.Generic;
using MessagePack;
using StackExchange.Redis;

namespace YemenBooking.Infrastructure.Redis.Models
{
    /// <summary>
    /// نموذج فهرس الوحدة السكنية
    /// يحتوي على جميع بيانات الوحدة للبحث والفلترة
    /// </summary>
    [MessagePackObject]
    public class UnitIndexDocument
    {
        /// <summary>
        /// معرف الوحدة الفريد
        /// </summary>
        [Key(0)]
        public Guid Id { get; set; }
        
        /// <summary>
        /// معرف العقار التابعة له
        /// </summary>
        [Key(1)]
        public Guid PropertyId { get; set; }
        
        /// <summary>
        /// اسم الوحدة
        /// </summary>
        [Key(2)]
        public string Name { get; set; }
        
        /// <summary>
        /// معرف نوع الوحدة
        /// </summary>
        [Key(3)]
        public Guid UnitTypeId { get; set; }
        
        /// <summary>
        /// اسم نوع الوحدة
        /// </summary>
        [Key(4)]
        public string UnitTypeName { get; set; }
        
        /// <summary>
        /// السعة القصوى للأشخاص
        /// </summary>
        [Key(5)]
        public int MaxCapacity { get; set; }
        
        /// <summary>
        /// عدد البالغين المسموح
        /// </summary>
        [Key(6)]
        public int MaxAdults { get; set; }
        
        /// <summary>
        /// عدد الأطفال المسموح
        /// </summary>
        [Key(7)]
        public int MaxChildren { get; set; }
        
        /// <summary>
        /// السعر الأساسي
        /// </summary>
        [Key(8)]
        public decimal BasePrice { get; set; }
        
        /// <summary>
        /// العملة
        /// </summary>
        [Key(9)]
        public string Currency { get; set; }
        
        /// <summary>
        /// عدد غرف النوم
        /// </summary>
        [Key(10)]
        public int BedroomsCount { get; set; }
        
        /// <summary>
        /// عدد الحمامات
        /// </summary>
        [Key(11)]
        public int BathroomsCount { get; set; }
        
        /// <summary>
        /// المساحة بالمتر المربع
        /// </summary>
        [Key(12)]
        public double AreaSquareMeters { get; set; }
        
        /// <summary>
        /// رقم الطابق
        /// </summary>
        [Key(13)]
        public int FloorNumber { get; set; }
        
        /// <summary>
        /// هل الوحدة نشطة
        /// </summary>
        [Key(14)]
        public bool IsActive { get; set; }
        
        /// <summary>
        /// هل الوحدة متاحة للحجز
        /// </summary>
        [Key(15)]
        public bool IsAvailable { get; set; }
        
        /// <summary>
        /// المرافق الخاصة بالوحدة
        /// </summary>
        [Key(16)]
        public List<string> UnitAmenities { get; set; } = new();
        
        /// <summary>
        /// الخصائص الديناميكية
        /// </summary>
        [Key(17)]
        public Dictionary<string, string> DynamicFields { get; set; } = new();
        
        /// <summary>
        /// تاريخ الإنشاء
        /// </summary>
        [Key(18)]
        public DateTime CreatedAt { get; set; }
        
        /// <summary>
        /// تاريخ آخر تحديث
        /// </summary>
        [Key(19)]
        public DateTime UpdatedAt { get; set; }
        
        /// <summary>
        /// تحويل إلى HashEntry للتخزين في Redis
        /// </summary>
        public HashEntry[] ToHashEntries()
        {
            return new[]
            {
                new HashEntry("id", Id.ToString()),
                new HashEntry("property_id", PropertyId.ToString()),
                new HashEntry("name", Name ?? ""),
                new HashEntry("unit_type_id", UnitTypeId.ToString()),
                new HashEntry("unit_type", UnitTypeName ?? ""),
                new HashEntry("max_capacity", MaxCapacity),
                new HashEntry("max_adults", MaxAdults),
                new HashEntry("max_children", MaxChildren),
                new HashEntry("base_price", BasePrice.ToString()),
                new HashEntry("currency", Currency ?? "YER"),
                new HashEntry("bedrooms", BedroomsCount),
                new HashEntry("bathrooms", BathroomsCount),
                new HashEntry("area_sqm", AreaSquareMeters),
                new HashEntry("floor", FloorNumber),
                new HashEntry("is_active", IsActive ? "1" : "0"),
                new HashEntry("is_available", IsAvailable ? "1" : "0"),
                new HashEntry("created_at", CreatedAt.Ticks),
                new HashEntry("updated_at", UpdatedAt.Ticks)
            };
        }

    }

    /// <summary>
    /// فترة تسعير
    /// </summary>
    [MessagePackObject]
    public class PriceRange
    {
        /// <summary>
        /// تاريخ البداية
        /// </summary>
        [Key(0)]
        public DateTime StartDate { get; set; }

        /// <summary>
        /// تاريخ النهاية
        /// </summary>
        [Key(1)]
        public DateTime EndDate { get; set; }

        /// <summary>
        /// السعر لليلة
        /// </summary>
        [Key(2)]
        public decimal PricePerNight { get; set; }

        /// <summary>
        /// العملة
        /// </summary>
        [Key(3)]
        public string Currency { get; set; } = "YER";

        /// <summary>
        /// تحويل إلى تنسيق Redis: startTicks:endTicks:price:currency
        /// </summary>
        public string ToRedisFormat() => $"{StartDate.Ticks}:{EndDate.Ticks}:{PricePerNight}:{Currency}";

        /// <summary>
        /// إنشاء من تنسيق Redis
        /// </summary>
        public static PriceRange FromRedisFormat(string value)
        {
            var parts = value.Split(':');
            return new PriceRange
            {
                StartDate = new DateTime(long.Parse(parts[0])),
                EndDate = new DateTime(long.Parse(parts[1])),
                PricePerNight = decimal.Parse(parts[2]),
                Currency = parts.Length > 3 ? parts[3] : "YER"
            };
        }
    }

    /// <summary>
    /// نموذج فهرس الإتاحة للوحدة
    /// يحتوي على فترات الإتاحة والحجوزات
    /// </summary>
    [MessagePackObject]
    public class AvailabilityIndexDocument
    {
        /// <summary>
        /// معرف الوحدة
        /// </summary>
        [Key(0)]
        public Guid UnitId { get; set; }
        
        /// <summary>
        /// معرف العقار
        /// </summary>
        [Key(1)]
        public Guid PropertyId { get; set; }
        
        /// <summary>
        /// قائمة فترات الإتاحة
        /// </summary>
        [Key(2)]
        public List<AvailabilityRange> AvailableRanges { get; set; } = new();
        
        /// <summary>
        /// قائمة فترات الحجز
        /// </summary>
        [Key(3)]
        public List<BookedRange> BookedRanges { get; set; } = new();
        
        /// <summary>
        /// تاريخ آخر تحديث
        /// </summary>
        [Key(4)]
        public DateTime LastUpdated { get; set; }
        
        /// <summary>
        /// عدد الأيام المتاحة في الشهر الحالي
        /// </summary>
        [Key(5)]
        public int AvailableDaysCurrentMonth { get; set; }
        
        /// <summary>
        /// معدل الإشغال الشهري
        /// </summary>
        [Key(6)]
        public decimal MonthlyOccupancyRate { get; set; }
    }

    /// <summary>
    /// فترة إتاحة
    /// </summary>
    [MessagePackObject]
    public class AvailabilityRange
    {
        /// <summary>
        /// تاريخ البداية
        /// </summary>
        [Key(0)]
        public DateTime StartDate { get; set; }
        
        /// <summary>
        /// تاريخ النهاية
        /// </summary>
        [Key(1)]
        public DateTime EndDate { get; set; }
        
        /// <summary>
        /// هل الفترة قابلة للحجز
        /// </summary>
        [Key(2)]
        public bool IsBookable { get; set; }
        
        /// <summary>
        /// سبب عدم الإتاحة (إن وجد)
        /// </summary>
        [Key(3)]
        public string BlockReason { get; set; }
        
        /// <summary>
        /// تحويل إلى تنسيق Redis
        /// </summary>
        public string ToRedisFormat() => $"{StartDate.Ticks}:{EndDate.Ticks}";
        
        /// <summary>
        /// إنشاء من تنسيق Redis
        /// </summary>
        public static AvailabilityRange FromRedisFormat(string value)
        {
            var parts = value.Split(':');
            return new AvailabilityRange
            {
                StartDate = new DateTime(long.Parse(parts[0])),
                EndDate = new DateTime(long.Parse(parts[1])),
                IsBookable = true
            };
        }
    }

    /// <summary>
    /// فترة محجوزة
    /// </summary>
    [MessagePackObject]
    public class BookedRange
    {
        /// <summary>
        /// معرف الحجز
        /// </summary>
        [Key(0)]
        public Guid BookingId { get; set; }
        
        /// <summary>
        /// تاريخ الوصول
        /// </summary>
        [Key(1)]
        public DateTime CheckIn { get; set; }
        
        /// <summary>
        /// تاريخ المغادرة
        /// </summary>
        [Key(2)]
        public DateTime CheckOut { get; set; }
        
        /// <summary>
        /// حالة الحجز
        /// </summary>
        [Key(3)]
        public string Status { get; set; }
    }

    /// <summary>
    /// نموذج فهرس التسعير الديناميكي للوحدة
    /// يحتوي على قواعد التسعير المختلفة
    /// </summary>
    [MessagePackObject]
    public class PricingIndexDocument
    {
        /// <summary>
        /// معرف الوحدة
        /// </summary>
        [Key(0)]
        public Guid UnitId { get; set; }
        
        /// <summary>
        /// معرف العقار
        /// </summary>
        [Key(1)]
        public Guid PropertyId { get; set; }
        
        /// <summary>
        /// السعر الأساسي
        /// </summary>
        [Key(2)]
        public decimal BasePrice { get; set; }
        
        /// <summary>
        /// العملة
        /// </summary>
        [Key(3)]
        public string Currency { get; set; }
        
        /// <summary>
        /// قواعد التسعير الموسمي
        /// </summary>
        [Key(4)]
        public List<SeasonalPricingRule> SeasonalRules { get; set; } = new();
        
        /// <summary>
        /// قواعد تسعير نهاية الأسبوع
        /// </summary>
        [Key(5)]
        public List<WeekendPricingRule> WeekendRules { get; set; } = new();
        
        /// <summary>
        /// قواعد التسعير الخاصة
        /// </summary>
        [Key(6)]
        public List<SpecialPricingRule> SpecialRules { get; set; } = new();
        
        /// <summary>
        /// خصومات الإقامة الطويلة
        /// </summary>
        [Key(7)]
        public List<LongStayDiscount> LongStayDiscounts { get; set; } = new();
        
        /// <summary>
        /// رسوم إضافية
        /// </summary>
        [Key(8)]
        public List<AdditionalFee> AdditionalFees { get; set; } = new();
        
        /// <summary>
        /// تاريخ آخر تحديث
        /// </summary>
        [Key(9)]
        public DateTime LastUpdated { get; set; }
    }

    /// <summary>
    /// قاعدة التسعير الموسمي
    /// </summary>
    [MessagePackObject]
    public class SeasonalPricingRule
    {
        /// <summary>
        /// اسم الموسم
        /// </summary>
        [Key(0)]
        public string SeasonName { get; set; }
        
        /// <summary>
        /// تاريخ بداية الموسم
        /// </summary>
        [Key(1)]
        public DateTime StartDate { get; set; }
        
        /// <summary>
        /// تاريخ نهاية الموسم
        /// </summary>
        [Key(2)]
        public DateTime EndDate { get; set; }
        
        /// <summary>
        /// السعر أو نسبة التغيير
        /// </summary>
        [Key(3)]
        public decimal PriceOrPercentage { get; set; }
        
        /// <summary>
        /// نوع التسعير (fixed/percentage)
        /// </summary>
        [Key(4)]
        public string PriceType { get; set; }
    }

    /// <summary>
    /// قاعدة تسعير نهاية الأسبوع
    /// </summary>
    [MessagePackObject]
    public class WeekendPricingRule
    {
        /// <summary>
        /// أيام نهاية الأسبوع المطبقة
        /// </summary>
        [Key(0)]
        public List<DayOfWeek> WeekendDays { get; set; } = new();
        
        /// <summary>
        /// السعر أو نسبة التغيير
        /// </summary>
        [Key(1)]
        public decimal PriceOrPercentage { get; set; }
        
        /// <summary>
        /// نوع التسعير (fixed/percentage)
        /// </summary>
        [Key(2)]
        public string PriceType { get; set; }
    }

    /// <summary>
    /// قاعدة التسعير الخاصة
    /// </summary>
    [MessagePackObject]
    public class SpecialPricingRule
    {
        /// <summary>
        /// اسم المناسبة
        /// </summary>
        [Key(0)]
        public string EventName { get; set; }
        
        /// <summary>
        /// تاريخ البداية
        /// </summary>
        [Key(1)]
        public DateTime StartDate { get; set; }
        
        /// <summary>
        /// تاريخ النهاية
        /// </summary>
        [Key(2)]
        public DateTime EndDate { get; set; }
        
        /// <summary>
        /// السعر أو نسبة التغيير
        /// </summary>
        [Key(3)]
        public decimal PriceOrPercentage { get; set; }
        
        /// <summary>
        /// نوع التسعير (fixed/percentage)
        /// </summary>
        [Key(4)]
        public string PriceType { get; set; }
    }

    /// <summary>
    /// خصم الإقامة الطويلة
    /// </summary>
    [MessagePackObject]
    public class LongStayDiscount
    {
        /// <summary>
        /// الحد الأدنى لعدد الليالي
        /// </summary>
        [Key(0)]
        public int MinNights { get; set; }
        
        /// <summary>
        /// نسبة الخصم
        /// </summary>
        [Key(1)]
        public decimal DiscountPercentage { get; set; }
    }

    /// <summary>
    /// رسوم إضافية
    /// </summary>
    [MessagePackObject]
    public class AdditionalFee
    {
        /// <summary>
        /// اسم الرسم
        /// </summary>
        [Key(0)]
        public string FeeName { get; set; }
        
        /// <summary>
        /// المبلغ
        /// </summary>
        [Key(1)]
        public decimal Amount { get; set; }
        
        /// <summary>
        /// نوع الرسم (per_night/per_stay/per_person)
        /// </summary>
        [Key(2)]
        public string FeeType { get; set; }
        
        /// <summary>
        /// هل الرسم اختياري
        /// </summary>
        [Key(3)]
        public bool IsOptional { get; set; }
    }
}
