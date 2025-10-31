using System;
using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان فلاتر البحث
/// SearchFilter entity representing filters for dynamic fields
/// </summary>
[Display(Name = "كيان فلاتر البحث")]
public class SearchFilter : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الحقل المرتبط
    /// Field identifier
    /// </summary>
    [Display(Name = "معرف الحقل المرتبط")]
    public Guid FieldId { get; set; }

    /// <summary>
    /// نوع الفلتر (range, exact, contains, boolean, select)
    /// Filter type
    /// </summary>
    [Display(Name = "نوع الفلتر")]
    public string FilterType { get; set; }

    /// <summary>
    /// الاسم المعروض للفلتر
    /// Display name of the filter
    /// </summary>
    [Display(Name = "الاسم المعروض للفلتر")]
    public string DisplayName { get; set; }

    /// <summary>
    /// خيارات إضافية للفلتر (JSON)
    /// Filter options
    /// </summary>
    [Display(Name = "خيارات إضافية للفلتر")]
    public string FilterOptions { get; set; }

    /// <summary>
    /// حالة تفعيل الفلتر
    /// Is active
    /// </summary>
    [Display(Name = "حالة تفعيل الفلتر")]
    public bool IsActive { get; set; }

    /// <summary>
    /// ترتيب عرض الفلتر
    /// Sort order
    /// </summary>
    [Display(Name = "ترتيب عرض الفلتر")]
    public int SortOrder { get; set; }

    /// <summary>
    /// علاقة الحقل المرتبط
    /// Property type field associated with this filter
    /// </summary>
    [Display(Name = "علاقة الحقل المرتبط")]
    public virtual UnitTypeField UnitTypeField { get; set; }
} 