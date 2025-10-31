using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Application.Features.Bookings.Commands.CreateBooking;

namespace YemenBooking.Application.Features.Bookings.Commands.CreateBooking;

/// <summary>
/// أمر إنشاء حجز جديد
/// Command to create new booking
/// </summary>
public class CreateBookingCommand : IRequest<ResultDto<CreateBookingResponse>>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// معرف الوحدة المطلوب حجزها
    /// </summary>
    public Guid UnitId { get; set; }
    
    /// <summary>
    /// تاريخ الوصول
    /// </summary>
    public DateTime CheckIn { get; set; }
    
    /// <summary>
    /// تاريخ المغادرة
    /// </summary>
    public DateTime CheckOut { get; set; }
    
    /// <summary>
    /// عدد الضيوف
    /// </summary>
    public int GuestsCount { get; set; }
    
    /// <summary>
    /// الخدمات الإضافية المطلوبة
    /// </summary>
    public List<BookingServiceRequest> Services { get; set; } = new();
    
    /// <summary>
    /// ملاحظات خاصة
    /// </summary>
    public string? SpecialRequests { get; set; }
    
    /// <summary>
    /// مصدر الحجز (تطبيق الموبايل)
    /// </summary>
    public string BookingSource { get; set; } = "MobileApp";
}

/// <summary>
/// طلب خدمة في الحجز
/// </summary>
public class BookingServiceRequest
{
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
/// استجابة إنشاء الحجز
/// </summary>
public class CreateBookingResponse
{
    /// <summary>
    /// معرف الحجز الجديد
    /// </summary>
    public Guid BookingId { get; set; }
    
    /// <summary>
    /// رقم الحجز
    /// </summary>
    public string BookingNumber { get; set; } = string.Empty;
    
    /// <summary>
    /// السعر الإجمالي
    /// </summary>
    public Money TotalPrice { get; set; } = null!;
    
    /// <summary>
    /// حالة الحجز
    /// </summary>
    public BookingStatus Status { get; set; }
    
    /// <summary>
    /// رسالة التأكيد
    /// </summary>
    public string Message { get; set; } = string.Empty;
}