namespace YemenBooking.Application.Features.DynamicFields.DTOs;
using System;

/// <summary>
/// بيانات نقل قيمة حقل عام
/// DTO for field value updates (generic)
/// </summary>
public class FieldValueDto
{
    /// <summary>
    /// معرف الحقل
    /// FieldId
    /// </summary>
    public Guid FieldId { get; set; }

    /// <summary>
    /// قيمة الحقل
    /// FieldValue
    /// </summary>
    public string FieldValue { get; set; }
} 