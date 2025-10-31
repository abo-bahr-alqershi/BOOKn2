using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reports.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Reports.Queries.GetAllReports;

/// <summary>
/// استعلام للحصول على جميع البلاغات
/// Query to get all reports with optional filters
/// </summary>
public class GetAllReportsQuery : IRequest<PaginatedResult<ReportDto>>
{
    /// <summary>
    /// رقم الصفحة
    /// Page number
    /// </summary>
    public int PageNumber { get; set; } = 1;

    /// <summary>
    /// حجم الصفحة
    /// Page size
    /// </summary>
    public int PageSize { get; set; } = 10;

    /// <summary>
    /// معرف المستخدم المبلغ
    /// Reporter user identifier (optional)
    /// </summary>
    public Guid? ReporterUserId { get; set; }

    /// <summary>
    /// معرف المستخدم المبلغ عنه
    /// Reported user identifier (optional)
    /// </summary>
    public Guid? ReportedUserId { get; set; }

    /// <summary>
    /// معرف الكيان المبلغ عنه
    /// Reported property identifier (optional)
    /// </summary>
    public Guid? ReportedPropertyId { get; set; }

    /// <summary>
    /// سبب البلاغ filter
    /// </summary>
    public string? Reason { get; set; }

    /// <summary>
    /// حالة البلاغ filter
    /// </summary>
    public string? Status { get; set; }

    /// <summary>
    /// من تاريخ filter
    /// </summary>
    public DateTime? FromDate { get; set; }

    /// <summary>
    /// إلى تاريخ filter
    /// </summary>
    public DateTime? ToDate { get; set; }

    /// <summary>
    /// نص البحث filter
    /// </summary>
    public string? SearchTerm { get; set; }
} 