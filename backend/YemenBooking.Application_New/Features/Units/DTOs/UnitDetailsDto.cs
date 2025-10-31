using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.DynamicFields.DTOs;

namespace YemenBooking.Application.Features.Units.DTOs;

/// <summary>
/// تفاصيل الوحدة
/// Unit details data transfer object
/// </summary>
public class UnitDetailsDto
{
    /// <summary>
    /// معرف الوحدة
    /// Unit ID
    /// </summary>
    public Guid Id { get; set; }
    
    /// <summary>
    /// معرف العقار
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// اسم العقار
    /// Property name
    /// </summary>
    public string PropertyName { get; set; } = string.Empty;
    
    /// <summary>
    /// اسم الوحدة
    /// Unit name
    /// </summary>
    public string Name { get; set; } = string.Empty;
    
    /// <summary>
    /// نوع الوحدة
    /// Unit type
    /// </summary>
    public UnitTypeDto UnitType { get; set; } = null!;
    
    /// <summary>
    /// معرف نوع الوحدة
    /// Unit type ID
    /// </summary>
    public Guid UnitTypeId { get; set; }
    
    /// <summary>
    /// اسم نوع الوحدة
    /// Unit type name
    /// </summary>
    public string UnitTypeName { get; set; } = string.Empty;
    
    /// <summary>
    /// السعر الأساسي
    /// Base price
    /// </summary>
    public MoneyDto BasePrice { get; set; } = null!;
    
    /// <summary>
    /// العملة (اختياري إذا كان MoneyDto لا يغطي)
    /// Currency (optional if MoneyDto covers it)
    /// </summary>
    public string? Currency { get; set; }
    
    /// <summary>
    /// السعة القصوى
    /// Maximum capacity
    /// </summary>
    public int MaxCapacity { get; set; }
    
    /// <summary>
    /// عدد المشاهدات
    /// View count
    /// </summary>
    public int ViewCount { get; set; }
    
    /// <summary>
    /// عدد الحجوزات
    /// BookingDto count
    /// </summary>
    public int BookingCount { get; set; }
    
    /// <summary>
    /// طريقة حساب السعر
    /// Pricing method
    /// </summary>
    public string PricingMethod { get; set; } = string.Empty;
    
    /// <summary>
    /// حالة التوفر
    /// Availability status
    /// </summary>
    public bool IsAvailable { get; set; }
    
    /// <summary>
    /// الصور
    /// Images
    /// </summary>
    public List<UnitImageDto> Images { get; set; } = new();
    
    /// <summary>
    /// الميزات المخصصة (JSON string)
    /// Custom features (JSON string)
    /// </summary>
    public string CustomFeatures { get; set; } = string.Empty;
    
    /// <summary>
    /// قيم الحقول الديناميكية
    /// Dynamic field values
    /// </summary>
    public List<UnitFieldValueDto> FieldValues { get; set; } = new();

    /// <summary>
    /// مجموعات الحقول مع القيم (ديناميكية)
    /// Dynamic field groups with values
    /// </summary>
    public List<FieldGroupWithValuesDto> DynamicFields { get; set; } = new();
    
    /// <summary>
    /// قواعد التسعير المطبقة
    /// Applied pricing rules
    /// </summary>
    public List<PricingRuleDto> PricingRules { get; set; } = new();
    
    /// <summary>
    /// السعر المحسوب للفترة المحددة
    /// Calculated price for specified period
    /// </summary>
    public CalculatedPriceDto? CalculatedPrice { get; set; }

    /// <summary>
    /// هل تقبل الوحدة الإلغاء
    /// Allows cancellation
    /// </summary>
    public bool AllowsCancellation { get; set; }

    /// <summary>
    /// نافذة الإلغاء بالأيام
    /// Cancellation window in days
    /// </summary>
    public int? CancellationWindowDays { get; set; }
}

/// <summary>
/// بيانات قاعدة التسعير
/// Pricing rule data transfer object
/// </summary>
public class PricingRuleDto
{
    /// <summary>
    /// نوع السعر
    /// Price type
    /// </summary>
    public string PriceType { get; set; } = string.Empty;
    
    /// <summary>
    /// تاريخ البداية
    /// Start date
    /// </summary>
    public DateTime StartDate { get; set; }
    
    /// <summary>
    /// تاريخ النهاية
    /// End date
    /// </summary>
    public DateTime EndDate { get; set; }
    
    /// <summary>
    /// مبلغ السعر
    /// Price amount
    /// </summary>
    public decimal PriceAmount { get; set; }
    
    /// <summary>
    /// الوصف
    /// Description
    /// </summary>
    public string? Description { get; set; }
}

/// <summary>
/// السعر المحسوب
/// Calculated price data transfer object
/// </summary>
public class CalculatedPriceDto
{
    /// <summary>
    /// السعر الأساسي
    /// Base amount
    /// </summary>
    public decimal BaseAmount { get; set; }
    
    /// <summary>
    /// الخصومات
    /// Discounts
    /// </summary>
    public decimal Discounts { get; set; }
    
    /// <summary>
    /// الرسوم الإضافية
    /// Additional fees
    /// </summary>
    public decimal Fees { get; set; }
    
    /// <summary>
    /// الضرائب
    /// Taxes
    /// </summary>
    public decimal Taxes { get; set; }
    
    /// <summary>
    /// السعر الإجمالي
    /// Total amount
    /// </summary>
    public decimal TotalAmount { get; set; }
    
    /// <summary>
    /// عدد الليالي
    /// Number of nights
    /// </summary>
    public int NumberOfNights { get; set; }
    
    /// <summary>
    /// تفاصيل حساب السعر
    /// Price calculation breakdown
    /// </summary>
    public List<PriceBreakdownDto> Breakdown { get; set; } = new();
}

/// <summary>
/// تفصيل السعر
/// Price breakdown data transfer object
/// </summary>
public class PriceBreakdownDto
{
    /// <summary>
    /// التاريخ
    /// Date
    /// </summary>
    public DateTime Date { get; set; }
    
    /// <summary>
    /// السعر لهذا اليوم
    /// Amount for this day
    /// </summary>
    public decimal Amount { get; set; }
    
    /// <summary>
    /// السبب (عادي، نهاية أسبوع، موسم ذروة، إلخ)
    /// Reason (normal, weekend, peak season, etc.)
    /// </summary>
    public string Reason { get; set; } = string.Empty;
}
