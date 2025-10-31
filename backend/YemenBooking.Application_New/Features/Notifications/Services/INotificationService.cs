using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using System;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Notifications;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Bookings.DTOs;

using YemenBooking.Application.Features.Payments.DTOs;

namespace YemenBooking.Application.Features.Notifications.Services;

/// <summary>
/// خدمة الإشعارات
/// Notification service interface
/// </summary>
public interface INotificationService
{
    /// <summary>
    /// إرسال إشعار للضيف بخصوص ملاحظة
    /// Send guest note notification
    /// </summary>
    Task SendGuestNoteNotificationAsync(GuestNoteNotification notification, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إرسال إشعار للفندق بخصوص ملاحظة
    /// Send hotel note notification
    /// </summary>
    Task SendHotelNoteNotificationAsync(HotelNoteNotification notification, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إرسال إشعار للمشرفين بخصوص ملاحظة عالية الأولوية
    /// Send high priority note notification
    /// </summary>
    Task SendHighPriorityNoteNotificationAsync(HighPriorityNoteNotification notification, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إرسال إشعار تأكيد الحجز
    /// Send booking confirmation notification
    /// </summary>
    Task SendBookingConfirmationAsync(BookingDto booking, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إرسال إشعار تسجيل الوصول
    /// Send check-in notification
    /// </summary>
    Task SendCheckInNotificationAsync(BookingDto booking, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إرسال إشعار تسجيل المغادرة
    /// Send check-out notification
    /// </summary>
    Task SendCheckOutNotificationAsync(BookingDto booking, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إرسال إشعار إلغاء الحجز
    /// Send booking cancellation notification
    /// </summary>
    Task SendBookingCancellationAsync(BookingDto booking, string reason, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إرسال إشعار تذكير بالحجز
    /// Send booking reminder notification
    /// </summary>
    Task SendBookingReminderAsync(BookingDto booking, int daysBefore, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إرسال إشعار دفع
    /// Send payment notification
    /// </summary>
    Task SendPaymentNotificationAsync(BookingDto booking, decimal amount, PaymentStatusDto status, CancellationToken cancellationToken = default);

    /// <summary>
    /// إرسال إشعار بتغيير توفر الغرفة
    /// Send room availability changed notification
    /// </summary>
    Task SendRoomAvailabilityChangedNotificationAsync(
        RoomAvailabilityChangedNotification notification,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إرسال إشعار بتغيير حالة الغرفة
    /// Send room status changed notification
    /// </summary>
    Task SendRoomStatusChangedNotificationAsync(
        RoomStatusChangedNotification notification,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إرسال إشعار بتأثر الحجز بسبب تغيير حالة الغرفة
    /// Send booking affected by room status change notification
    /// </summary>
    Task SendBookingAffectedByRoomStatusChangeNotificationAsync(
        Guid bookingId,
        Guid roomId,
        string newRoomStatus,
        string reason,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إرسال تأكيد تسجيل المغادرة
    /// Send check-out confirmation
    /// </summary>
    Task SendCheckOutConfirmationAsync(Guid bookingId, Guid customerId);

    /// <summary>
    /// إرسال إشعار تسجيل المغادرة للفندق
    /// Send hotel check-out notification
    /// </summary>
    Task SendHotelCheckOutNotificationAsync(Guid bookingId, Guid hotelId);

    /// <summary>
    /// إرسال تأكيد تسجيل الوصول
    /// Send check-in confirmation
    /// </summary>
    Task SendCheckInConfirmationAsync(Guid bookingId, Guid customerId, string wifiPassword);

    /// <summary>
    /// إرسال إشعار تسجيل الوصول للفندق
    /// Send hotel check-in notification
    /// </summary>
    Task SendHotelCheckInNotificationAsync(Guid bookingId, Guid hotelId);

    /// <summary>
    /// إرسال إشعار عام
    /// Send a generic notification request
    /// </summary>
    Task SendAsync(NotificationRequest request, CancellationToken cancellationToken = default);
}

/// <summary>
/// إشعار ملاحظة الضيف
/// Guest note notification
/// </summary>
public class GuestNoteNotification
{
    public Guid BookingId { get; set; }
    public string BookingNumber { get; set; } = null!;
    public string GuestName { get; set; } = null!;
    public string? GuestEmail { get; set; }
    public string? NoteTitle { get; set; }
    public string NoteContent { get; set; } = null!;
    public bool RequiresResponse { get; set; }
    public DateTime? DueDate { get; set; }
}

/// <summary>
/// إشعار ملاحظة الفندق
/// Hotel note notification
/// </summary>
public class HotelNoteNotification
{
    public Guid BookingId { get; set; }
    public string BookingNumber { get; set; } = null!;
    public Guid HotelId { get; set; }
    public string? NoteTitle { get; set; }
    public string NoteContent { get; set; } = null!;
    public string CreatedByUser { get; set; } = null!;
    public bool RequiresResponse { get; set; }
}

/// <summary>
/// إشعار ملاحظة عالية الأولوية
/// High priority note notification
/// </summary>
public class HighPriorityNoteNotification
{
    public Guid BookingId { get; set; }
    public string BookingNumber { get; set; } = null!;
    public Guid NoteId { get; set; }
    public string? NoteTitle { get; set; }
    public string NoteContent { get; set; } = null!;
    public string CreatedByUser { get; set; } = null!;
    public DateTime CreatedAt { get; set; }
}

/// <summary>
/// إشعار تغيير توفر الغرفة
/// Room availability changed notification
/// </summary>
public class RoomAvailabilityChangedNotification
{
    public Guid RoomId { get; set; }
    public string RoomNumber { get; set; } = null!;
    public Guid HotelId { get; set; }
    public string AvailabilityType { get; set; } = null!;
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public string? Reason { get; set; }
    public Guid? UpdatedByUserId { get; set; }
}

/// <summary>
/// إشعار تغيير حالة الغرفة
/// Room status changed notification
/// </summary>
public class RoomStatusChangedNotification
{
    public Guid RoomId { get; set; }
    public string RoomNumber { get; set; } = null!;
    public Guid HotelId { get; set; }
    public string PreviousStatus { get; set; } = null!;
    public string NewStatus { get; set; } = null!;
    public string Reason { get; set; } = null!;
    public string Priority { get; set; } = null!;
    public Guid ChangedByUserId { get; set; }
    public int AffectedBookingsCount { get; set; }
    public DateTime? EffectiveStartDate { get; set; }
    public DateTime? ExpectedEndDate { get; set; }
    public Guid? AssignedToUserId { get; set; }
}
