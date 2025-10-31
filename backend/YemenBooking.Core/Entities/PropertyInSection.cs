namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;
using System.Collections.Generic;

/// <summary>
/// كيان العقار داخل القسم بمعلومات مخزنة للأداء
/// </summary>
[Display(Name = "عقار في قسم")]
public class PropertyInSection : BaseEntity<Guid>
{
    // المعرفات
    [Display(Name = "معرف القسم")]
    public Guid SectionId { get; set; }

    [Display(Name = "معرف العقار")]
    public Guid PropertyId { get; set; }

    // بيانات العقار المخزنة
    [Display(Name = "اسم العقار")]
    public string PropertyName { get; set; } = string.Empty;

    [Display(Name = "العنوان")]
    public string Address { get; set; } = string.Empty;

    [Display(Name = "المدينة")]
    public string City { get; set; } = string.Empty;

    [Display(Name = "خط العرض")]
    public decimal Latitude { get; set; }

    [Display(Name = "خط الطول")]
    public decimal Longitude { get; set; }

    [Display(Name = "نوع العقار")]
    public string PropertyType { get; set; } = string.Empty;

    [Display(Name = "تصنيف النجوم")]
    public int StarRating { get; set; }

    [Display(Name = "متوسط التقييم")]
    public decimal AverageRating { get; set; }

    [Display(Name = "عدد التقييمات")]
    public int ReviewsCount { get; set; }

    [Display(Name = "السعر الأساسي")]
    public decimal BasePrice { get; set; }

    [Display(Name = "العملة")]
    public string Currency { get; set; } = string.Empty;

    [Display(Name = "الصورة الرئيسية")]
    public virtual string? MainImage { get; set; }

	/// <summary>
    /// صور إضافية مخصصة لسجل العقار في القسم
	/// </summary>
	[Display(Name = "صور إضافية")]
    public virtual ICollection<PropertyInSectionImage> AdditionalImages { get; set; } = new List<PropertyInSectionImage>();

    [Display(Name = "الوصف المختصر")]
    public string? ShortDescription { get; set; }

    // إعدادات العرض
    [Display(Name = "ترتيب العرض")]
    public int DisplayOrder { get; set; } = 0;

    [Display(Name = "مميز في القسم")]
    public bool IsFeatured { get; set; } = false;

    [Display(Name = "نسبة الخصم")]
    public decimal? DiscountPercentage { get; set; }

    [Display(Name = "رسالة ترويجية")]
    public string? PromotionalText { get; set; }

    [Display(Name = "شارة")]
    public Badge? Badge { get; set; }

    [Display(Name = "لون الشارة")]
    public string? BadgeColor { get; set; }

    // الفترة الزمنية
    [Display(Name = "عرض من تاريخ")]
    public DateTime? DisplayFrom { get; set; }

    [Display(Name = "عرض حتى تاريخ")]
    public DateTime? DisplayUntil { get; set; }

    [Display(Name = "أولوية العرض")]
    public int Priority { get; set; } = 0;

    // الإحصائيات
    [Display(Name = "عدد المشاهدات من القسم")]
    public int ViewsFromSection { get; set; } = 0;

    [Display(Name = "عدد النقرات")]
    public int ClickCount { get; set; } = 0;

    [Display(Name = "معدل التحويل")]
    public decimal? ConversionRate { get; set; }

    // البيانات الإضافية
    [Display(Name = "الميتاداتا (JSON)")]
    public string? Metadata { get; set; }

    // العلاقات
    [Display(Name = "القسم")]
    public virtual Section Section { get; set; }

    [Display(Name = "العقار")]
    public virtual Property Property { get; set; }
}

