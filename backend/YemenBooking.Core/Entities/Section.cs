namespace YemenBooking.Core.Entities;

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;

/// <summary>
/// كيان قسم العرض في الواجهة
/// Section entity for grouping content on home screens and lists
/// </summary>
[Display(Name = "كيان القسم")]
public class Section : BaseEntity<Guid>
{
	/// <summary>
	/// اسم القسم
	/// </summary>
	[Display(Name = "اسم القسم")]
	public string? Name { get; set; }

	/// <summary>
	/// عنوان القسم
	/// </summary>
	[Display(Name = "عنوان القسم")]
	public string? Title { get; set; }

	/// <summary>
	/// العنوان الفرعي
	/// </summary>
	[Display(Name = "العنوان الفرعي")]
	public string? Subtitle { get; set; }

	/// <summary>
	/// الوصف
	/// </summary>
	[Display(Name = "الوصف")]
	public string? Description { get; set; }

	/// <summary>
	/// الوصف المختصر
	/// </summary>
	[Display(Name = "الوصف المختصر")]
	public string? ShortDescription { get; set; }

	/// <summary>
	/// نوع القسم (حسب التعداد)
	/// </summary>
	[Display(Name = "نوع القسم")]
	public SectionType Type { get; set; }

	/// <summary>
	/// نوع المحتوى: عقارات/وحدات/مختلط
	/// </summary>
	[Display(Name = "نوع المحتوى")]
	public ContentType ContentType { get; set; } = ContentType.Properties;

	/// <summary>
	/// نمط العرض: شبكة/قائمة/دائري/خريطة
	/// </summary>
	[Display(Name = "نمط العرض")]
	public DisplayStyle DisplayStyle { get; set; } = DisplayStyle.Grid;

	/// <summary>
	/// عدد الأعمدة
	/// </summary>
	[Display(Name = "عدد الأعمدة")]
	public int ColumnsCount { get; set; } = 2;

	/// <summary>
	/// عدد العناصر للعرض
	/// </summary>
	[Display(Name = "عدد العناصر للعرض")]
	public int ItemsToShow { get; set; } = 10;

	/// <summary>
	/// ترتيب عرض القسم
	/// </summary>
	[Display(Name = "ترتيب القسم")]
	public int DisplayOrder { get; set; }

	/// <summary>
	/// هل القسم يستهدف الكيانات أم الوحدات
	/// </summary>
	[Display(Name = "هدف القسم")] 
	public SectionTarget Target { get; set; }

	/// <summary>
	/// أيقونة القسم
	/// </summary>
	[Display(Name = "أيقونة القسم")]
	public string? Icon { get; set; }

	/// <summary>
	/// لون القسم
	/// </summary>
	[Display(Name = "لون القسم")]
	public string? ColorTheme { get; set; }

	/// <summary>
	/// صورة الخلفية
	/// </summary>
	[Display(Name = "صورة الخلفية")]
	public string? BackgroundImage { get; set; }

	/// <summary>
	/// معرف صورة الخلفية من جدول الصور الموحد (اختياري)
	/// </summary>
	[Display(Name = "معرف صورة الخلفية")]
	public Guid? BackgroundImageId { get; set; }

	/// <summary>
	/// معايير الفلترة (JSON)
	/// </summary>
	[Display(Name = "معايير الفلترة (JSON)")]
	public string? FilterCriteria { get; set; }

	/// <summary>
	/// معايير الترتيب (JSON)
	/// </summary>
	[Display(Name = "معايير الترتيب (JSON)")]
	public string? SortCriteria { get; set; }

	/// <summary>
	/// اسم المدينة (كمفتاح نصي متوافق مع النظام)
	/// </summary>
	[Display(Name = "اسم المدينة")]
	public string? CityName { get; set; }

	/// <summary>
	/// معرف نوع العقار
	/// </summary>
	[Display(Name = "معرف نوع العقار")]
	public Guid? PropertyTypeId { get; set; }

	/// <summary>
	/// معرف نوع الوحدة
	/// </summary>
	[Display(Name = "معرف نوع الوحدة")]
	public Guid? UnitTypeId { get; set; }

	/// <summary>
	/// نطاق السعر الأدنى
	/// </summary>
	[Display(Name = "نطاق السعر الأدنى")]
	public decimal? MinPrice { get; set; }

	/// <summary>
	/// نطاق السعر الأعلى
	/// </summary>
	[Display(Name = "نطاق السعر الأعلى")]
	public decimal? MaxPrice { get; set; }

	/// <summary>
	/// التقييم الأدنى
	/// </summary>
	[Display(Name = "التقييم الأدنى")]
	public decimal? MinRating { get; set; }

	/// <summary>
	/// مرئي للضيوف
	/// </summary>
	[Display(Name = "مرئي للضيوف")]
	public bool IsVisibleToGuests { get; set; } = true;

	/// <summary>
	/// مرئي للمستخدمين المسجلين
	/// </summary>
	[Display(Name = "مرئي للمستخدمين المسجلين")]
	public bool IsVisibleToRegistered { get; set; } = true;

	/// <summary>
	/// يتطلب صلاحيات خاصة
	/// </summary>
	[Display(Name = "يتطلب صلاحيات خاصة")]
	public string? RequiresPermission { get; set; }

	/// <summary>
	/// تاريخ البداية
	/// </summary>
	[Display(Name = "تاريخ البداية")]
	public DateTime? StartDate { get; set; }

	/// <summary>
	/// تاريخ النهاية
	/// </summary>
	[Display(Name = "تاريخ النهاية")]
	public DateTime? EndDate { get; set; }

	/// <summary>
	/// ميتاداتا إضافية (JSON)
	/// </summary>
	[Display(Name = "الميتاداتا (JSON)")]
	public string? Metadata { get; set; }

    /// <summary>
    /// الفئة الخاصة بنوع القسم (Class A, B, C, D)
    /// </summary>
    [Display(Name = "فئة القسم")]
    public SectionClass? CategoryClass { get; set; }

    /// <summary>
    /// عدد العناصر التي ستظهر في الصفحة الرئيسية (يتجاوز ItemsToShow عند الحاجة)
    /// </summary>
    [Display(Name = "عدد عناصر الصفحة الرئيسية")]
    public int? HomeItemsCount { get; set; }

    /// <summary>
    /// قائمة العقارات في القسم (كيان غني)
    /// </summary>
    [Display(Name = "قائمة العقارات في القسم")]
    public virtual ICollection<PropertyInSection> PropertyItems { get; set; } = new List<PropertyInSection>();

	/// <summary>
	/// قائمة الوحدات في القسم (كيان غني)
	/// </summary>
    [Display(Name = "قائمة الوحدات في القسم")]
	public virtual ICollection<UnitInSection> UnitItems { get; set; } = new List<UnitInSection>();

	/// <summary>
    /// صور القسم المخصصة (خلفيات، أغلفة، إلخ)
	/// </summary>
	[Display(Name = "صور القسم")]
    public virtual ICollection<SectionImage> Images { get; set; } = new List<SectionImage>();
}