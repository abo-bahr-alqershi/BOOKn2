using System;
using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان ربط الحقول والمجموعات
/// FieldGroupField entity representing link between fields and groups
/// </summary>
[Display(Name = "كيان ربط الحقول والمجموعات")]
public class FieldGroupField : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الحقل
    /// Field identifier
    /// </summary>
    [Display(Name = "معرف الحقل")]
    public Guid FieldId { get; set; }

    /// <summary>
    /// معرف المجموعة
    /// Group identifier
    /// </summary>
    [Display(Name = "معرف المجموعة")]
    public Guid GroupId { get; set; }

    /// <summary>
    /// ترتيب الحقل داخل المجموعة
    /// Sort order within the group
    /// </summary>
    [Display(Name = "ترتيب الحقل داخل المجموعة")]
    public int SortOrder { get; set; }

    /// <summary>
    /// العلاقة مع الحقل
    /// Property type field associated
    /// </summary>
    [Display(Name = "العلاقة مع الحقل")]
    public virtual UnitTypeField UnitTypeField { get; set; }

    /// <summary>
    /// العلاقة مع المجموعة
    /// Field group associated
    /// </summary>
    [Display(Name = "العلاقة مع المجموعة")]
    public virtual FieldGroup FieldGroup { get; set; }
} 