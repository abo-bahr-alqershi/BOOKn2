namespace YemenBooking.Core.Entities;

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان نوع الوحدة
/// Unit Type entity
/// </summary>
[Display(Name = "كيان نوع الوحدة")]
public class UnitType : BaseEntity<Guid>
{
    /// <summary>
    /// وصف نوع الوحدة
    /// Description of the unit type
    /// </summary>
    [Display(Name = "وصف نوع الوحدة")]
    public string Description { get; set; }

    /// <summary>
    /// قواعد التسعير الافتراضية (JSON)
    /// Default pricing rules (JSON)
    /// </summary>
    [Display(Name = "قواعد التسعير الافتراضية")]
    public string DefaultPricingRules { get; set; }

    /// <summary>
    /// معرف نوع الكيان
    /// Property type identifier
    /// </summary>
    [Display(Name = "معرف نوع الكيان")]
    public Guid PropertyTypeId { get; set; }

    /// <summary>
    /// اسم نوع الوحدة (غرفة مزدوجة، جناح، شاليه كامل، فيلا)
    /// Unit type name (Double Room, Suite, Full Chalet, Villa)
    /// </summary>
    [Display(Name = "اسم نوع الوحدة")]
    public string Name { get; set; }

    /// <summary>
    /// الحد الأقصى للسعة
    /// Maximum capacity
    /// </summary>
    [Display(Name = "الحد الأقصى للسعة")]
    public int MaxCapacity { get; set; }

    /// <summary>
    /// ايقونة لنوع الوحدة
    /// Icon for the unit type
    /// </summary>
    public string Icon { get; set; } = string.Empty;

    /// <summary>
    /// هذا النوع يحتوي على بالغين
    /// This type has adults
    /// </summary>
    public bool IsHasAdults { get; set; } = false;

    /// <summary>
    /// هذا النوع يحتوي على أطفال
    /// This type has children
    /// </summary>
    public bool IsHasChildren { get; set; } = false;

    /// <summary>
    /// هذا النوع يحتوي على أيام متعددة
    /// This type has multiple days
    /// </summary>
    public bool IsMultiDays { get; set; } = false;

    /// <summary>
    /// هذا النوع يحتاج لتحديد الساعة
    /// This type requires determining the hour
    /// </summary>
    public bool IsRequiredToDetermineTheHour { get; set; } = false;

    /// <summary>
    /// نسبة العمولة الخاصة بالنظام (بوكن) لهذا النوع (%)
    /// System commission rate for Bookn (percentage 0-100)
    /// </summary>
    [Display(Name = "نسبة عمولة النظام")]
    public decimal? SystemCommissionRate { get; set; }

    /// <summary>
    /// نوع الكيان المرتبط
    /// Property type associated
    /// </summary>
    [Display(Name = "نوع الكيان المرتبط")]
    public virtual PropertyType PropertyType { get; set; }

    /// <summary>
    /// الوحدات المرتبطة بهذا النوع
    /// Units associated with this type
    /// </summary>
    [Display(Name = "الوحدات المرتبطة بهذا النوع")]
    public virtual ICollection<Unit> Units { get; set; } = new List<Unit>();
    
    /// <summary>
    /// الحقول الديناميكية لنوع الوحدة
    /// Dynamic fields associated with this unit type
    /// </summary>
    [Display(Name = "الحقول الديناميكية لنوع الوحدة")]
    public virtual ICollection<UnitTypeField> UnitTypeFields { get; set; } = new List<UnitTypeField>();

    /// <summary>
    /// مجموعات الحقول لنوع الوحدة
    /// Field groups associated with this unit type
    /// </summary>
    [Display(Name = "مجموعات الحقول لنوع الوحدة")]
    public virtual ICollection<FieldGroup> FieldGroups { get; set; } = new List<FieldGroup>();

    /// <summary>
    /// الفلاتر المخصصة لنوع الوحدة
    /// Search filters associated with this unit type fields
    /// </summary>
    [Display(Name = "الفلاتر المخصصة لنوع الوحدة")]
    public virtual ICollection<SearchFilter> SearchFilters { get; set; } = new List<SearchFilter>();

} 