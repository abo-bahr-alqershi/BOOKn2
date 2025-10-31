namespace YemenBooking.Application.Features.DynamicFields.DTOs;
using System;

/// <summary>
/// طلب ترتيب الحقول
/// DTO for field ordering
/// </summary>
public class FieldOrderDto
{
    /// <summary>
    /// معرف الحقل
    /// FieldId
    /// </summary>
    public Guid FieldId { get; set; }

    /// <summary>
    /// ترتيب الحقل
    /// SortOrder
    /// </summary>
    public int SortOrder { get; set; }
} 