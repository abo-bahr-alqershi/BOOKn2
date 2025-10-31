using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Reports.Commands.ManageReports;

/// <summary>
/// أمر لتحديث بلاغ
/// Command to update an existing report
/// </summary>
public class UpdateReportCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف البلاغ
    /// Report identifier
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// السبب الجديد (اختياري)
    /// New reason (optional)
    /// </summary>
    public string? Reason { get; set; }

    /// <summary>
    /// تفاصيل البلاغ الجديدة (اختياري)
    /// New description (optional)
    /// </summary>
    public string? Description { get; set; }
} 