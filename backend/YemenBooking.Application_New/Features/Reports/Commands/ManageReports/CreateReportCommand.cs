using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Reports.Commands.ManageReports;

/// <summary>
/// أمر لإنشاء بلاغ جديد
/// Command to create a new report
/// </summary>
public class CreateReportCommand : IRequest<ResultDto<Guid>>
{
    /// <summary>
    /// معرف المستخدم المبلغ
    /// Reporter user identifier
    /// </summary>
    public Guid ReporterUserId { get; set; }

    /// <summary>
    /// معرف المستخدم المبلغ عنه (اختياري)
    /// Reported user identifier (optional)
    /// </summary>
    public Guid? ReportedUserId { get; set; }

    /// <summary>
    /// معرف الكيان المبلغ عنه (اختياري)
    /// Reported property identifier (optional)
    /// </summary>
    public Guid? ReportedPropertyId { get; set; }

    /// <summary>
    /// سبب البلاغ
    /// Reason for the report
    /// </summary>
    public string Reason { get; set; } = string.Empty;

    /// <summary>
    /// تفاصيل البلاغ
    /// Report description
    /// </summary>
    public string Description { get; set; } = string.Empty;
} 