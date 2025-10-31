using System;
using YemenBooking.Core.Interfaces;
using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان قيم الحقول للوحدات
/// UnitFieldValue entity representing custom field values on units
/// </summary>
[Display(Name = "كيان قيم الحقول للوحدات")]
public class UnitFieldValue : BaseEntity<Guid>, IFieldValue
{
    /// <summary>
    /// معرف الوحدة
    /// Unit identifier
    /// </summary>
    [Display(Name = "معرف الوحدة")]
    public Guid UnitId { get; set; }

    /// <summary>
    /// معرف حقل نوع الوحدة
    /// Property type field identifier
    /// </summary>
    [Display(Name = "معرف حقل نوع الوحدة")]
    public Guid UnitTypeFieldId { get; set; }

    /// <summary>
    /// قيمة الحقل
    /// Field value
    /// </summary>
    [Display(Name = "قيمة الحقل")]
    public string FieldValue { get; set; } = string.Empty;

    /// <summary>
    /// الوحدة المرتبطة
    /// Unit associated
    /// </summary>
    [Display(Name = "الوحدة المرتبطة")]
    public virtual Unit? Unit { get; set; }

    /// <summary>
    /// الحقل المرتبط
    /// Property type field associated
    /// </summary>
    [Display(Name = "الحقل المرتبط")]
    public virtual UnitTypeField? UnitTypeField { get; set; }
} 