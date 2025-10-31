using System;

namespace YemenBooking.Application.Features.Reports.DTOs;

/// <summary>
/// DTO لبيانات البلاغ
/// DTO for report data
/// </summary>
public class ReportDto
{
    /// <summary>
    /// معرف البلاغ
    /// Report identifier
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// معرف المستخدم المبلغ
    /// Reporter user identifier
    /// </summary>
    public Guid ReporterUserId { get; set; }

    /// <summary>
    /// اسم المستخدم المبلغ
    /// Reporter user name
    /// </summary>
    public string ReporterUserName { get; set; } = string.Empty;

    /// <summary>
    /// معرف المستخدم المبلغ عنه (اختياري)
    /// Reported user identifier (optional)
    /// </summary>
    public Guid? ReportedUserId { get; set; }

    /// <summary>
    /// اسم المستخدم المبلغ عنه (اختياري)
    /// Reported user name (optional)
    /// </summary>
    public string? ReportedUserName { get; set; }

    /// <summary>
    /// معرف الكيان المبلغ عنه (اختياري)
    /// Reported property identifier (optional)
    /// </summary>
    public Guid? ReportedPropertyId { get; set; }

    /// <summary>
    /// اسم الكيان المبلغ عنه (اختياري)
    /// Reported property name (optional)
    /// </summary>
    public string? ReportedPropertyName { get; set; }

    /// <summary>
    /// سبب البلاغ
    /// Reason for the report
    /// </summary>
    public string Reason { get; set; } = string.Empty;

    /// <summary>
    /// تفاصيل البلاغ
    /// Detailed description of the report
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// تاريخ إنشاء البلاغ
    /// Report creation date
    /// </summary>
    public DateTime CreatedAt { get; set; }
} 