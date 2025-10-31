using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان مجموعات الحقول
/// FieldGroup entity representing grouping of fields per property type
/// </summary>
[Display(Name = "كيان مجموعات الحقول")]
public class FieldGroup : BaseEntity<Guid>
{
    /// <summary>
    /// معرف نوع الكيان
    /// Property type identifier
    /// </summary>
    [Display(Name = "معرف نوع الو​​​​حدة")]
    public Guid UnitTypeId { get; set; }

    /// <summary>
    /// اسم المجموعة
    /// Group name
    /// </summary>
    [Display(Name = "اسم المجموعة")]
    public string GroupName { get; set; }

    /// <summary>
    /// الاسم المعروض للمجموعة
    /// Display name of the group
    /// </summary>
    [Display(Name = "الاسم المعروض للمجموعة")]
    public string DisplayName { get; set; }

    /// <summary>
    /// وصف المجموعة
    /// Description of the group
    /// </summary>
    [Display(Name = "وصف المجموعة")]
    public string Description { get; set; }

    /// <summary>
    /// ترتيب العرض
    /// Sort order of the group
    /// </summary>
    [Display(Name = "ترتيب العرض")]
    public int SortOrder { get; set; }

    /// <summary>
    /// هل يمكن طي المجموعة
    /// Is collapsible
    /// </summary>
    [Display(Name = "هل يمكن طي المجموعة")]
    public bool IsCollapsible { get; set; }

    /// <summary>
    /// هل تكون المجموعة موسعة افتراضياً
    /// Is expanded by default
    /// </summary>
    [Display(Name = "هل تكون المجموعة موسعة افتراضيًا")]
    public bool IsExpandedByDefault { get; set; }

    /// <summary>
    /// نوع الوحدة المرتبطة
    /// Unit type associated
    /// </summary>
    [Display(Name = "نوع الوحدة المرتبطة")]
    public virtual UnitType UnitType { get; set; }

    /// <summary>
    /// روابط الحقول ضمن هذه المجموعة
    /// Field group links
    /// </summary>
    [Display(Name = "روابط الحقول ضمن هذه المجموعة")]
    public virtual ICollection<FieldGroupField> FieldGroupFields { get; set; } = new List<FieldGroupField>();
} 