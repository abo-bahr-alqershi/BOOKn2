

using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Units.DTOs;

/// <summary>
/// استجابة الوحدات المتاحة
/// Available units response data transfer object
/// </summary>
public class AvailableUnitsResponse
{
    /// <summary>
    /// قائمة الوحدات المتاحة
    /// List of available units
    /// </summary>
    public List<AvailableUnitDto> Units { get; set; } = new();
    
    /// <summary>
    /// إجمالي عدد الوحدات المتاحة
    /// Total number of available units
    /// </summary>
    public int TotalAvailable { get; set; }
}

/// <summary>
/// بيانات الوحدة المتاحة
/// Available unit data transfer object
/// </summary>
public class AvailableUnitDto
{
    /// <summary>
    /// معرف الوحدة
    /// Unit ID
    /// </summary>
    public Guid Id { get; set; }
    
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
    /// السعة القصوى
    /// Maximum capacity
    /// </summary>
    public int MaxCapacity { get; set; }
    
    /// <summary>
    /// السعر للفترة المحددة
    /// Total price for specified period
    /// </summary>
    public decimal TotalPrice { get; set; }
    
    /// <summary>
    /// السعر الأساسي لليلة الواحدة
    /// Base price per night
    /// </summary>
    public decimal PricePerNight { get; set; }
    
    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    public string Currency { get; set; } = string.Empty;
    
    /// <summary>
    /// طريقة حساب السعر
    /// Pricing method
    /// </summary>
    public string PricingMethod { get; set; } = string.Empty;
    
    /// <summary>
    /// الصور
    /// Images
    /// </summary>
    public List<UnitImageDto> Images { get; set; } = new();
    
    /// <summary>
    /// الميزات المخصصة
    /// Custom features
    /// </summary>
    public Dictionary<string, object> CustomFeatures { get; set; } = new();
    
    /// <summary>
    /// قيم الحقول الديناميكية
    /// Dynamic field values
    /// </summary>
    public List<UnitFieldSimpleDto> FieldValues { get; set; } = new();
}

/// <summary>
/// بيانات صورة الوحدة
/// Unit image data transfer object
/// </summary>
public class UnitImageDto
{
    /// <summary>
    /// معرف الصورة
    /// Image ID
    /// </summary>
    public Guid Id { get; set; }
    
    /// <summary>
    /// رابط الصورة
    /// Image URL
    /// </summary>
    public string Url { get; set; } = string.Empty;
    
    /// <summary>
    /// التسمية التوضيحية
    /// Caption
    /// </summary>
    public string Caption { get; set; } = string.Empty;
    
    /// <summary>
    /// هل هي الصورة الرئيسية
    /// Is main image
    /// </summary>
    public bool IsMain { get; set; }
}

/// <summary>
/// بيانات قيمة الحقل
/// Unit field value data transfer object
/// </summary>



public class UnitFieldSimpleDto
{
    /// <summary>
    /// اسم الحقل
    /// Field name
    /// </summary>
    public string FieldName { get; set; } = string.Empty;
    
    /// <summary>
    /// الاسم المعروض
    /// Display name
    /// </summary>
    public string DisplayName { get; set; } = string.Empty;
    
    /// <summary>
    /// القيمة
    /// Value
    /// </summary>
    public string Value { get; set; } = string.Empty;
    
    /// <summary>
    /// نوع الحقل
    /// Field type
    /// </summary>
    public string FieldType { get; set; } = string.Empty;
    // Extended properties for internal mapping
    public Guid ValueId { get; set; }
    public Guid UnitId { get; set; }
    public Guid FieldId { get; set; }
    public string FieldValue { get; set; } = string.Empty;
    public UnitTypeFieldDto Field { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
