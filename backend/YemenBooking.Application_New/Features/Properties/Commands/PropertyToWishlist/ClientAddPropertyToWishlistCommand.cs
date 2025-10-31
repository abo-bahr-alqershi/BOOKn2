using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Properties.Commands.PropertyToWishlist;

/// <summary>
/// أمر إضافة العقار لقائمة الأمنيات للعميل
/// Command to add property to wishlist for client
/// </summary>
public class ClientAddPropertyToWishlistCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف العقار
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }

    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// ملاحظات خاصة (اختياري)
    /// Special notes (optional)
    /// </summary>
    public string? Notes { get; set; }

    /// <summary>
    /// تاريخ الزيارة المطلوبة (اختياري)
    /// Desired visit date (optional)
    /// </summary>
    public DateTime? DesiredVisitDate { get; set; }

    /// <summary>
    /// الميزانية المتوقعة (اختياري)
    /// Expected budget (optional)
    /// </summary>
    public decimal? ExpectedBudget { get; set; }

    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    public string Currency { get; set; } = "YER";
}