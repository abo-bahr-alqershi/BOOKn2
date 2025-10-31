using System;
using System.Collections.Generic;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Services.DTOs;
using YemenBooking.Application.Features.Payments.DTOs;

namespace YemenBooking.Application.Features.Bookings.DTOs {
    /// <summary>
    /// DTO لتفاصيل الحجز
    /// BookingDto details DTO
    /// </summary>
    public class BookingDetailsDto
    {
        // New properties to align with MobileApp handler expectations
        public string PropertyAddress { get; set; } = string.Empty;

        public DateTime CheckIn { get; set; }
        public DateTime CheckOut { get; set; }

        public int GuestsCount { get; set; }

        public DateTime BookedAt { get; set; }
        public string? BookingSource { get; set; }
        public string? CancellationReason { get; set; }
        public bool IsWalkIn { get; set; }
        public decimal? PlatformCommissionAmount { get; set; }
        public DateTime? ActualCheckInDate { get; set; }
        public DateTime? ActualCheckOutDate { get; set; }
        public decimal? FinalAmount { get; set; }
        public int? CustomerRating { get; set; }
        public string? CompletionNotes { get; set; }

        public List<BookingServiceDto> Services { get; set; } = new();
        public List<PaymentDto> Payments { get; set; } = new();
        public List<string> UnitImages { get; set; } = new();
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
        /// معرف المستخدم
        /// User ID
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// اسم المستخدم
        /// User name
        /// </summary>
        public string UserName { get; set; } = string.Empty;

        /// <summary>
        /// معرف العقار
        /// Property ID
        /// </summary>
        public Guid PropertyId { get; set; }

        /// <summary>
        /// اسم العقار
        /// Property name
        /// </summary>
        public string PropertyName { get; set; } = string.Empty;

        /// <summary>
        /// معرف الوحدة
        /// Unit ID
        /// </summary>
        public Guid? UnitId { get; set; }

        /// <summary>
        /// اسم الوحدة
        /// Unit name
        /// </summary>
        public string? UnitName { get; set; }

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
        /// عدد الضيوف البالغين
        /// Number of adult guests
        /// </summary>
        public int AdultGuests { get; set; }

        /// <summary>
        /// عدد الضيوف الأطفال
        /// Number of child guests
        /// </summary>
        public int ChildGuests { get; set; }

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
        /// السعر الإجمالي ككائن Money (للتوافق مع Flutter)
        /// Total price as Money object (for Flutter compatibility)
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
        public DateTime BookingDate { get; set; }

        /// <summary>
        /// ملاحظات خاصة
        /// Special notes
        /// </summary>
        public string? SpecialNotes { get; set; }

        /// <summary>
        /// معلومات الاتصال
        /// Contact information
        /// </summary>
        public ContactInfoDto ContactInfo { get; set; } = new();

        /// <summary>
        /// تفاصيل الدفع
        /// Payment details
        /// </summary>
        public List<YemenBooking.Application.Features.Payments.DTOs.PaymentDetailsDto> PaymentDetails { get; set; } = new();

        /// <summary>
        /// لقطة سياسات العقار وقت إنشاء الحجز (JSON)
        /// Property policy snapshot at booking time (JSON)
        /// </summary>
        public string? PolicySnapshot { get; set; }

        /// <summary>
        /// وقت حفظ لقطة السياسات
        /// When the policy snapshot was captured
        /// </summary>
        public DateTime? PolicySnapshotAt { get; set; }
    }

    /// <summary>
    /// DTO لمعلومات الاتصال
    /// Contact information DTO
    /// </summary>
    public class ContactInfoDto
    {
        /// <summary>
        /// رقم الهاتف
        /// Phone number
        /// </summary>
        public string PhoneNumber { get; set; } = string.Empty;

        /// <summary>
        /// البريد الإلكتروني
        /// Email address
        /// </summary>
        public string Email { get; set; } = string.Empty;
    }
}
