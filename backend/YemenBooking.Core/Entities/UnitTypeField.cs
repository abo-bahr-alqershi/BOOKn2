using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان حقول نوع الكيان
/// UnitTypeField entity representing dynamic fields for a property type
/// </summary>
[Display(Name = "كيان حقول نوع الكيان")]
public class UnitTypeField : BaseEntity<Guid>
{
    /// <summary>
    /// معرف نوع الكيان
    /// Property type identifier
    /// </summary>
    [Display(Name = "معرف نوع الكيان")]
    public Guid UnitTypeId { get; set; }

    /// <summary>
    /// معرف نوع الحقل
    /// Field type identifier
    /// </summary>
    [Display(Name = "معرف نوع الحقل")]
    public string FieldTypeId { get; set; }

    /// <summary>
    /// اسم الحقل
    /// Field name
    /// </summary>
    [Display(Name = "اسم الحقل")]
    public string FieldName { get; set; }

    /// <summary>
    /// الاسم المعروض للحقل
    /// Display name of the field
    /// </summary>
    [Display(Name = "الاسم المعروض للحقل")]
    public string DisplayName { get; set; }

    /// <summary>
    /// وصف الحقل
    /// Field description
    /// </summary>
    [Display(Name = "وصف الحقل")]
    public string Description { get; set; }

    /// <summary>
    /// خيارات الحقل في حالة select أو multi_select (JSON)
    /// Field options in case of select or multi-select
    /// </summary>
    [Display(Name = "خيارات الحقل")]
    public string FieldOptions { get; set; }

    /// <summary>
    /// قواعد التحقق المخصصة (JSON)
    /// Custom validation rules
    /// </summary>
    [Display(Name = "قواعد التحقق المخصصة")]
    public string ValidationRules { get; set; }

    /// <summary>
    /// هل الحقل إلزامي
    /// Is required
    /// </summary>
    [Display(Name = "هل الحقل إلزامي")]
    public bool IsRequired { get; set; }

    /// <summary>
    /// هل يظهر في الفلترة
    /// Is searchable
    /// </summary>
    [Display(Name = "هل يظهر في الفلترة")]
    public bool IsSearchable { get; set; }

    /// <summary>
    /// هل يظهر للعملاء
    /// Is public
    /// </summary>
    [Display(Name = "هل يظهر للعملاء")]
    public bool IsPublic { get; set; }

    /// <summary>
    /// ترتيب الحقل
    /// Sort order of the field
    /// </summary>
    [Display(Name = "ترتيب الحقل")]
    public int SortOrder { get; set; }

    /// <summary>
    /// فئة الحقل (basic, amenities, location, pricing)
    /// Category of the field
    /// </summary>
    [Display(Name = "فئة الحقل")]
    public string Category { get; set; }

    /// <summary>
    /// نوع الوحدة المرتبط
    /// Unit type associated
    /// </summary>
    [Display(Name = "نوع الوحدة المرتبط")]
    public virtual UnitType UnitType { get; set; }

    /// <summary>
    /// قيم الحقل للوحدات
    /// Field values for units
    /// </summary>
    [Display(Name = "قيم الحقل للوحدات")]
    public virtual ICollection<UnitFieldValue> UnitFieldValues { get; set; } = new List<UnitFieldValue>();

    /// <summary>
    /// انضمامات مجموعات الحقول
    /// Field group links
    /// </summary>
    [Display(Name = "انضمامات مجموعات الحقول")]
    public virtual ICollection<FieldGroupField> FieldGroupFields { get; set; } = new List<FieldGroupField>();

    /// <summary>
    /// الفلاتر المرتبطة بهذا الحقل
    /// Search filters associated with this field
    /// </summary>
    [Display(Name = "الفلاتر المرتبطة بهذا الحقل")]
    public virtual ICollection<SearchFilter> SearchFilters { get; set; } = new List<SearchFilter>();

    /// <summary>
    /// يحدد ما إذا كان الحقل مخصصاً للوحدات
    /// Indicates if the field applies to units
    /// </summary>
    [Display(Name = "مخصص للوحدات")]
    public bool IsForUnits { get; set; }
    /// <summary>
    /// هل يظهر في الكروت؟
    /// Show in cards
    /// </summary>
    [Display(Name = "هل يظهر في الكروت؟")]
    public bool ShowInCards { get; set; }

    /// <summary>
    /// هل الحقل فلترة أساسية؟
    /// Is primary filter
    /// </summary>
    [Display(Name = "هل الحقل فلترة أساسية؟")]
    public bool IsPrimaryFilter { get; set; }

    /// <summary>
    /// أولوية الترتيب
    /// Order priority
    /// </summary>
    [Display(Name = "أولوية الترتيب")]
    public int Priority { get; set; }
} 