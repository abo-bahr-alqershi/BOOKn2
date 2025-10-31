namespace YemenBooking.Application.Common.Models;
using System;

/// <summary>
/// طلب ترتيب المجموعات
/// DTO for group ordering
/// </summary>
public class GroupOrderDto
{
    /// <summary>
    /// معرف المجموعة
    /// GroupId
    /// </summary>
    public Guid GroupId { get; set; }

    /// <summary>
    /// ترتيب المجموعة
    /// SortOrder
    /// </summary>
    public int SortOrder { get; set; }
} 