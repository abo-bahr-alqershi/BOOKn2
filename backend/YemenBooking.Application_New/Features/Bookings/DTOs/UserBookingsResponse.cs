using System;
using System.Collections.Generic;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Bookings.DTOs {
    /// <summary>
    /// DTO لاستجابة حجوزات المستخدم
    /// User bookings response DTO
    /// </summary>
    public class UserBookingsResponse
    {
        /// <summary>
        /// قائمة الحجوزات
        /// List of bookings
        /// </summary>
        public List<UserBookingDto> Bookings { get; set; } = new();

        /// <summary>
        /// العدد الإجمالي للحجوزات
        /// Total bookings count
        /// </summary>
        public int TotalCount { get; set; }

        /// <summary>
        /// رقم الصفحة الحالية
        /// Current page number
        /// </summary>
        public int CurrentPage { get; set; }

        /// <summary>
        /// حجم الصفحة
        /// Page size
        /// </summary>
        public int PageSize { get; set; }

        /// <summary>
        /// العدد الإجمالي للصفحات
        /// Total pages count
        /// </summary>
        public int TotalPages { get; set; }

        /// <summary>
        /// هل توجد صفحة سابقة
        /// Has previous page
        /// </summary>
        public bool HasPreviousPage { get; set; }

        /// <summary>
        /// هل توجد صفحة تالية
        /// Has next page
        /// </summary>
        public bool HasNextPage { get; set; }
    }

    /// <summary>
    /// DTO لحجز المستخدم
    /// User booking DTO
    /// </summary>
    public class UserBookingDto
    {
        /// <summary>
        /// معرف الحجز
        /// BookingDto ID
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// رقم الحجز
        /// BookingDto number
        /// </summary>
        public string BookingNumber { get; set; } = string.Empty;

        /// <summary>
        /// اسم العقار
        /// Property name
        /// </summary>
        public string PropertyName { get; set; } = string.Empty;

        /// <summary>
        /// صورة العقار
        /// Property image
        /// </summary>
        public string PropertyImage { get; set; } = string.Empty;

        /// <summary>
        /// موقع العقار
        /// Property location
        /// </summary>
        public string PropertyLocation { get; set; } = string.Empty;

        /// <summary>
        /// تاريخ الوصول
        /// Check-in date
        /// </summary>
        public DateTime CheckInDate { get; set; }

        /// <summary>
        /// تاريخ المغادرة
        /// Check-out date
        /// </summary>
        public DateTime CheckOutDate { get; set; }

        /// <summary>
        /// عدد الليالي
        /// Number of nights
        /// </summary>
        public int NumberOfNights { get; set; }

        /// <summary>
        /// عدد الضيوف
        /// Number of guests
        /// </summary>
        public int TotalGuests { get; set; }

        /// <summary>
        /// المبلغ الإجمالي
        /// Total amount
        /// </summary>
        public decimal TotalAmount { get; set; }

        /// <summary>
        /// العملة
        /// Currency
        /// </summary>
        public string Currency { get; set; } = "YER";

        /// <summary>
        /// حالة الحجز
        /// BookingDto status
        /// </summary>
        public BookingStatus Status { get; set; }

        /// <summary>
        /// نص حالة الحجز
        /// BookingDto status text
        /// </summary>
        public string StatusText { get; set; } = string.Empty;

        /// <summary>
        /// تاريخ الحجز
        /// BookingDto date
        /// </summary>
        public DateTime BookingDate { get; set; }

        /// <summary>
        /// هل يمكن إلغاء الحجز
        /// Can cancel booking
        /// </summary>
        public bool CanCancel { get; set; }

        /// <summary>
        /// هل يمكن تعديل الحجز
        /// Can modify booking
        /// </summary>
        public bool CanModify { get; set; }

        /// <summary>
        /// تقييم العقار (إذا تم)
        /// Property rating (if given)
        /// </summary>
        public int? Rating { get; set; }

        /// <summary>
        /// هل تم كتابة مراجعة
        /// Has written review
        /// </summary>
        public bool HasReview { get; set; }
    }
}
