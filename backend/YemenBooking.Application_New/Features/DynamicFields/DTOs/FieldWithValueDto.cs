namespace YemenBooking.Application.Features.DynamicFields.DTOs;
using System;

/// <summary>
/// بيانات نقل حقل مع قيمته
/// DTO for field with its value
/// </summary>
public class FieldWithValueDto
{
    /// <summary>
    /// معرف القيمة
    /// ValueId
    /// </summary>
    public Guid ValueId { get; set; }

    /// <summary>
    /// معرف الحقل
    /// FieldId
    /// </summary>
    public Guid FieldId { get; set; }

    /// <summary>
    /// اسم الحقل
    /// FieldName
    /// </summary>
    public string FieldName { get; set; } = string.Empty;

    /// <summary>
    /// الاسم المعروض للحقل
    /// DisplayName
    /// </summary>
    public string DisplayName { get; set; } = string.Empty;

    /// <summary>
    /// قيمة الحقل
    /// Value
    /// </summary>
    public string Value { get; set; } = string.Empty;

    /// <summary>
    /// هل الحقل فلترة أساسية؟
    /// Is primary filter
    /// </summary>
    public bool IsPrimaryFilter { get; set; }
}