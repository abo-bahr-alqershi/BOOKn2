using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Properties.Commands.UpdateProperty;

/// <summary>
/// أمر تحديث عدد مشاهدات العقار للعميل
/// Command to update property view count for client
/// </summary>
public class ClientUpdatePropertyViewCountCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف العقار
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }

    /// <summary>
    /// معرف المستخدم (اختياري)
    /// User ID (optional)
    /// </summary>
    public Guid? UserId { get; set; }

    /// <summary>
    /// عنوان IP للمستخدم
    /// User IP address
    /// </summary>
    public string? IpAddress { get; set; }

    /// <summary>
    /// معرف الجلسة
    /// Session ID
    /// </summary>
    public string? SessionId { get; set; }

    /// <summary>
    /// وقت المشاهدة
    /// View time
    /// </summary>
    public DateTime ViewedAt { get; set; } = DateTime.UtcNow;
}