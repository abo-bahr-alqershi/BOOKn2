namespace YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.DynamicFields.DTOs;
using YemenBooking.Application.Features.Units.DTOs;

using System;

/// <summary>
/// بيانات نقل قيمة حقل الكيان
/// DTO for PropertyFieldValue entity
/// </summary>
public class PropertyFieldValueDto
{
    /// <summary>
    /// معرف القيمة
    /// ValueId
    /// </summary>
    public Guid ValueId { get; set; }

    /// <summary>
    /// معرف الكيان
    /// PropertyId
    /// </summary>
    public Guid PropertyId { get; set; }

    /// <summary>
    /// معرف الحقل
    /// FieldId
    /// </summary>
    public Guid FieldId { get; set; }

    /// <summary>
    /// اسم الحقل
    /// FieldName
    /// </summary>
    public string FieldName { get; set; }

    /// <summary>
    /// الاسم المعروض
    /// DisplayName
    /// </summary>
    public string DisplayName { get; set; }

    /// <summary>
    /// قيمة الحقل
    /// FieldValue
    /// </summary>
    public string FieldValue { get; set; }

    /// <summary>
    /// معلومات الحقل الديناميكي
    /// Field (UnitTypeFieldDto)
    /// </summary>
    public UnitTypeFieldDto Field { get; set; }

    /// <summary>
    /// تاريخ الإنشاء
    /// CreatedAt
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// تاريخ التحديث
    /// UpdatedAt
    /// </summary>
    public DateTime UpdatedAt { get; set; }
} 