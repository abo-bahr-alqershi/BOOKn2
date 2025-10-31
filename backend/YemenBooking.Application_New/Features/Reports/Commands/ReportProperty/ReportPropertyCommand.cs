using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reports;
using YemenBooking.Application.Features.Reports.DTOs;

namespace YemenBooking.Application.Features.Reports.Commands.ReportProperty;

/// <summary>
/// أمر الإبلاغ عن كيان
/// Command to report property
/// </summary>
public class ReportPropertyCommand : IRequest<ResultDto<ReportPropertyResponse>>
{
    /// <summary>
    /// معرف المستخدم المبلغ
    /// </summary>
    public Guid ReporterUserId { get; set; }
    
    /// <summary>
    /// معرف الكيان المبلغ عنه
    /// </summary>
    public Guid ReportedPropertyId { get; set; }
    
    /// <summary>
    /// سبب البلاغ
    /// </summary>
    public string Reason { get; set; } = string.Empty;
    
    /// <summary>
    /// الوصف التفصيلي للمشكلة
    /// </summary>
    public string Description { get; set; } = string.Empty;
}