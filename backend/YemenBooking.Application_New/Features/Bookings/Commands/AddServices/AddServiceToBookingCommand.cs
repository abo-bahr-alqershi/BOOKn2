using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.ValueObjects;

namespace YemenBooking.Application.Features.Bookings.Commands.AddServices;

/// <summary>
/// أمر إضافة خدمة إلى الحجز
/// Command to add service to booking
/// </summary>
public class AddServicesToBookingCommand : IRequest<ResultDto<AddServicesToBookingResponse>>
{
    /// <summary>
    /// معرف الحجز
    /// </summary>
    public Guid BookingId { get; set; }
    
    /// <summary>
    /// معرف الخدمة
    /// </summary>
    public Guid ServiceId { get; set; }
    
    /// <summary>
    /// الكمية المطلوبة
    /// </summary>
    public int Quantity { get; set; }
}

/// <summary>
/// استجابة إضافة الخدمة
/// </summary>
public class AddServicesToBookingResponse
{
    /// <summary>
    /// نجاح الإضافة
    /// </summary>
    public bool Success { get; set; }
    
    /// <summary>
    /// السعر الإجمالي الجديد
    /// </summary>
    public Money NewTotalPrice { get; set; } = null!;
    
    /// <summary>
    /// رسالة النتيجة
    /// </summary>
    public string Message { get; set; } = string.Empty;
}