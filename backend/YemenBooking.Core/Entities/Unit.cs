namespace YemenBooking.Core.Entities;

using System;
using YemenBooking.Core.ValueObjects;
using System.Collections.Generic;
using YemenBooking.Core.Enums;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان الوحدة
/// Unit entity
/// </summary>
[Display(Name = "كيان الوحدة")]
public class Unit : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الكيان
    /// Property identifier
    /// </summary>
    [Display(Name = "معرف الكيان")]
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// معرف نوع الوحدة
    /// Unit type identifier
    /// </summary>
    [Display(Name = "معرف نوع الوحدة")]
    public Guid UnitTypeId { get; set; }
    
    /// <summary>
    /// اسم الوحدة (الوحدة A، الجناح الملكي)
    /// Unit name (Unit A, Royal Suite)
    /// </summary>
    [Display(Name = "اسم الوحدة")]
    public string Name { get; set; }
    
    /// <summary>
    /// السعر الأساسي للوحدة
    /// Base price of the unit
    /// </summary>
    [Display(Name = "السعر الأساسي للوحدة")]
    public Money BasePrice { get; set; }
    
    /// <summary>
    /// السعة القصوى للوحدة (عدد الضيوف الأقصى)
    /// Maximum capacity of the unit (max number of guests)
    /// </summary>
    [Display(Name = "السعة القصوى للوحدة")]
    public int MaxCapacity { get; set; }
    
    /// <summary>
    /// نسبة الخصم الافتراضية للوحدة (0-100)
    /// Default discount percentage for the unit (0-100)
    /// </summary>
    public decimal DiscountPercentage { get; set; } = 0;
    
    /// <summary>
    /// الميزات المخصصة للوحدة (JSON)
    /// Custom features of the unit (JSON)
    /// </summary>
    [Display(Name = "الميزات المخصصة للوحدة")]
    public string CustomFeatures { get; set; }
    
    /// <summary>
    /// حالة توفر الوحدة
    /// Unit availability status
    /// </summary>
    [Display(Name = "حالة توفر الوحدة")]
    public bool IsAvailable { get; set; } = true;

    /// <summary>
    /// عدد مرات المشاهدة
    /// View count
    /// </summary>
    [Display(Name = "عدد مرات المشاهدة")]
    public int ViewCount { get; set; } = 0;

    /// <summary>
    /// عدد الحجوزات
    /// Booking count
    /// </summary>
    [Display(Name = "عدد الحجوزات")]
    public int BookingCount { get; set; } = 0;
    
    /// <summary>
    /// هل تقبل الوحدة إلغاء الحجز
    /// Whether the unit allows booking cancellation
    /// </summary>
    [Display(Name = "تقبل إلغاء الحجز")]
    public bool AllowsCancellation { get; set; } = true;

    /// <summary>
    /// عدد أيام السماح بالإلغاء قبل موعد الوصول (إن وجد)
    /// Number of days before check-in when cancellation is allowed (optional)
    /// </summary>
    [Display(Name = "أيام نافذة الإلغاء قبل الوصول")]
    public int? CancellationWindowDays { get; set; }

    /// <summary>
    /// سعة البالغين
    /// Adults capacity
    /// </summary>
    [Display(Name = "سعة البالغين")]
    public int? AdultsCapacity { get; set; }

    /// <summary>
    /// سعة الأطفال
    /// Children capacity
    /// </summary>
    [Display(Name = "سعة الأطفال")]
    public int? ChildrenCapacity { get; set; }

    /// <summary>
    /// الكيان المرتبط بالوحدة
    /// Property associated with the unit
    /// </summary>
    [Display(Name = "الكيان المرتبط بالوحدة")]
    public virtual Property Property { get; set; }
    
    /// <summary>
    /// نوع الوحدة المرتبط
    /// Unit type associated
    /// </summary>
    [Display(Name = "نوع الوحدة المرتبط")]
    public virtual UnitType UnitType { get; set; }
    
    /// <summary>
    /// الحجوزات المرتبطة بالوحدة
    /// Bookings associated with the unit
    /// </summary>
    [Display(Name = "الحجوزات المرتبطة بالوحدة")]
    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();
    
    /// <summary>
    /// الصور المرتبطة بالوحدة
    /// Images associated with the unit
    /// </summary>
    [Display(Name = "الصور المرتبطة بالوحدة")]
    public virtual ICollection<PropertyImage> Images { get; set; } = new List<PropertyImage>();

    /// <summary>
    /// توضيح إتاحة الوحدة
    /// Navigation for unit availabilities
    /// </summary>
    public virtual ICollection<UnitAvailability> UnitAvailabilities { get; set; } = new List<UnitAvailability>();

    /// <summary>
    /// توضيح تسعير الوحدة
    /// Navigation for unit pricing
    /// </summary>
    public virtual ICollection<PricingRule> PricingRules { get; set; } = new List<PricingRule>();

    /// <summary>
    /// قيم الحقول الخاصة بالوحدة
    /// Field values associated with this unit
    /// </summary>
    [Display(Name = "قيم الحقول الخاصة بالوحدة")]
    public virtual ICollection<UnitFieldValue> FieldValues { get; set; } = new List<UnitFieldValue>();

    /// <summary>
    /// طريقة حساب السعر (بالساعة، اليوم، الأسبوع، الشهر)
    /// Pricing calculation method (Hourly, Daily, Weekly, Monthly)
    /// </summary>
    [Display(Name = "طريقة حساب السعر")]
    public PricingMethod PricingMethod { get; set; }

    // Legacy SectionItems removed in favor of rich entities UnitInSection

    /// <summary>
    /// سجلات الغنية للوحدة في الأقسام
    /// Rich section-unit records
    /// </summary>
    public virtual ICollection<UnitInSection> UnitInSections { get; set; } = new List<UnitInSection>();

} 