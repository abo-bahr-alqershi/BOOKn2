using System;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Bookings.DTOs {
    /// <summary>
    /// DTO لبيانات الحجز
    /// DTO for booking data
    /// </summary>
    public class BookingDto
    {
        /// <summary>
        /// معرف الحجز
        /// BookingDto identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// معرف المستخدم
        /// User identifier
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// معرف الوحدة
        /// Unit identifier
        /// </summary>
        public Guid UnitId { get; set; }

        /// <summary>
        /// تاريخ الوصول
        /// Check-in date
        /// </summary>
        public DateTime CheckIn { get; set; }

        /// <summary>
        /// تاريخ المغادرة
        /// Check-out date
        /// </summary>
        public DateTime CheckOut { get; set; }

        /// <summary>
        /// عدد الضيوف
        /// Number of guests
        /// </summary>
        public int GuestsCount { get; set; }

        /// <summary>
        /// السعر الإجمالي
        /// Total price
        /// </summary>
        public MoneyDto TotalPrice { get; set; }

        /// <summary>
        /// حالة الحجز
        /// BookingDto status
        /// </summary>
        public BookingStatus Status { get; set; }

        /// <summary>
        /// تاريخ الحجز
        /// BookingDto date
        /// </summary>
        public DateTime BookedAt { get; set; }

        /// <summary>
        /// اسم المستخدم
        /// User name
        /// </summary>
        public string UserName { get; set; }

        /// <summary>
        /// اسم الوحدة
        /// Unit name
        /// </summary>
        public string UnitName { get; set; }
    }
} 