using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Properties.Commands.ApproveProperty;

/// <summary>
/// أمر لرفض الكيان من قبل الإدارة
/// Command to reject a property by administration
/// </summary>
public class RejectPropertyCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الكيان
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }

    /// <summary>
    /// سبب الرفض
    /// Reason for rejection
    /// </summary>
    public string Reason { get; set; } = string.Empty;

    /// <summary>
    /// معرف المسؤول الذي قام بالرفض
    /// Admin ID who rejected
    /// </summary>
    public Guid AdminId { get; set; }
} 