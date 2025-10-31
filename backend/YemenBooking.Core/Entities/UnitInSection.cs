namespace YemenBooking.Core.Entities;

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;

/// <summary>
/// كيان الوحدة داخل القسم بمعلومات مخزنة للأداء
/// </summary>
[Display(Name = "وحدة في قسم")]
public class UnitInSection : BaseEntity<Guid>
{
    // المعرفات
    [Display(Name = "معرف القسم")]
    public Guid SectionId { get; set; }

    [Display(Name = "معرف الوحدة")]
    public Guid UnitId { get; set; }

    [Display(Name = "معرف العقار")]
    public Guid PropertyId { get; set; }

    // بيانات الوحدة المخزنة
    [Display(Name = "اسم الوحدة")]
    public string UnitName { get; set; } = string.Empty;

    [Display(Name = "اسم العقار")]
    public string PropertyName { get; set; } = string.Empty;

    [Display(Name = "نوع الوحدة - المعرف")]
    public Guid UnitTypeId { get; set; }

    [Display(Name = "نوع الوحدة - الاسم")]
    public string UnitTypeName { get; set; } = string.Empty;

    [Display(Name = "أيقونة نوع الوحدة")]
    public string? UnitTypeIcon { get; set; }

    [Display(Name = "السعة القصوى")]
    public int MaxCapacity { get; set; }

    [Display(Name = "السعر الأساسي")]
    public decimal BasePrice { get; set; }

    [Display(Name = "العملة")]
    public string Currency { get; set; } = string.Empty;

    [Display(Name = "طريقة التسعير")]
    public PricingMethod PricingMethod { get; set; }

    [Display(Name = "سعة البالغين")]
    public int? AdultsCapacity { get; set; }

    [Display(Name = "سعة الأطفال")]
    public int? ChildrenCapacity { get; set; }

    [Display(Name = "الصورة الرئيسية")]
    public virtual string? MainImage { get; set; }

    /// <summary>
    /// صور إضافية مخصصة لسجل الوحدة في القسم
    /// </summary>
    [Display(Name = "صور إضافية")]
    public virtual ICollection<UnitInSectionImage> AdditionalImages { get; set; } = new List<UnitInSectionImage>();

    // الحقول الديناميكية المهمة للعرض
    [Display(Name = "قيم الحقول الأساسية (JSON)")]
    public string? PrimaryFieldValues { get; set; }

    // معلومات العقار الأساسية
    [Display(Name = "عنوان العقار")]
    public string PropertyAddress { get; set; } = string.Empty;

    [Display(Name = "مدينة العقار")]
    public string PropertyCity { get; set; } = string.Empty;

    [Display(Name = "خط العرض")]
    public decimal Latitude { get; set; }

    [Display(Name = "خط الطول")]
    public decimal Longitude { get; set; }

    [Display(Name = "تصنيف نجوم العقار")]
    public int PropertyStarRating { get; set; }

    [Display(Name = "متوسط تقييم العقار")]
    public decimal PropertyAverageRating { get; set; }

    // الميزات والمرافق
    [Display(Name = "المرافق الرئيسية (JSON)")]
    public string? MainAmenities { get; set; }

    [Display(Name = "ميزات مخصصة (JSON)")]
    public string? CustomFeatures { get; set; }

    // إعدادات العرض
    [Display(Name = "ترتيب العرض")]
    public int DisplayOrder { get; set; } = 0;

    [Display(Name = "مميز في القسم")]
    public bool IsFeatured { get; set; } = false;

    [Display(Name = "نسبة الخصم")]
    public decimal? DiscountPercentage { get; set; }

    [Display(Name = "السعر بعد الخصم")]
    public decimal? DiscountedPrice { get; set; }

    [Display(Name = "رسالة ترويجية")]
    public string? PromotionalText { get; set; }

    [Display(Name = "شارة")]
    public Badge? Badge { get; set; }

    [Display(Name = "لون الشارة")]
    public string? BadgeColor { get; set; }

    // حالة التوفر
    [Display(Name = "متوفر")]
    public bool IsAvailable { get; set; } = true;

    [Display(Name = "تواريخ التوفر القادمة (JSON)")]
    public string? NextAvailableDates { get; set; }

    [Display(Name = "رسالة التوفر")]
    public string? AvailabilityMessage { get; set; }

    // الفترة الزمنية
    [Display(Name = "عرض من تاريخ")]
    public DateTime? DisplayFrom { get; set; }

    [Display(Name = "عرض حتى تاريخ")]
    public DateTime? DisplayUntil { get; set; }

    [Display(Name = "أولوية العرض")]
    public int Priority { get; set; } = 0;

    // إعدادات الحجز
    [Display(Name = "يقبل الإلغاء")]
    public bool AllowsCancellation { get; set; } = true;

    [Display(Name = "أيام نافذة الإلغاء")]
    public int? CancellationWindowDays { get; set; }

    [Display(Name = "الحد الأدنى للإقامة")]
    public int? MinStayDays { get; set; }

    [Display(Name = "الحد الأقصى للإقامة")]
    public int? MaxStayDays { get; set; }

    // الإحصائيات
    [Display(Name = "عدد المشاهدات من القسم")]
    public int ViewsFromSection { get; set; } = 0;

    [Display(Name = "عدد النقرات")]
    public int ClickCount { get; set; } = 0;

    [Display(Name = "معدل التحويل")]
    public decimal? ConversionRate { get; set; }

    [Display(Name = "عدد الحجوزات الأخيرة")]
    public int RecentBookingsCount { get; set; } = 0;

    // البيانات الإضافية
    [Display(Name = "الميتاداتا (JSON)")]
    public string? Metadata { get; set; }

    // العلاقات
    [Display(Name = "القسم")]
    public virtual Section Section { get; set; }

    [Display(Name = "الوحدة")]
    public virtual Unit Unit { get; set; }

    [Display(Name = "العقار")]
    public virtual Property Property { get; set; }
}

