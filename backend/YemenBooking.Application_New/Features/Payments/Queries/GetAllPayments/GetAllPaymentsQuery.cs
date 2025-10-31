using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Payments.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Payments.Queries.GetAllPayments
{
    /// <summary>
    /// استعلام لجلب جميع المدفوعات مع دعم الفلاتر
    /// Query to get all payments with various filters
    /// </summary>
    public class GetAllPaymentsQuery : IRequest<PaginatedResult<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>>
    {
        /// <summary>حالة الدفع filter</summary>
        public string? Status { get; set; }
        /// <summary>طريقة الدفع filter</summary>
        public string? Method { get; set; }
        /// <summary>معرف الحجز filter</summary>
        public Guid? BookingId { get; set; }
        /// <summary>معرف المستخدم filter</summary>
        public Guid? UserId { get; set; }
        /// <summary>معرف الكيان filter</summary>
        public Guid? PropertyId { get; set; }
        /// <summary>معرف الوحدة filter</summary>
        public Guid? UnitId { get; set; }
        /// <summary>الحد الأدنى للمبلغ filter</summary>
        public decimal? MinAmount { get; set; }
        /// <summary>الحد الأقصى للمبلغ filter</summary>
        public decimal? MaxAmount { get; set; }
        /// <summary>تاريخ البداية filter</summary>
        public DateTime? StartDate { get; set; }
        /// <summary>تاريخ النهاية filter</summary>
        public DateTime? EndDate { get; set; }
        /// <summary>رقم الصفحة</summary>
        public int PageNumber { get; set; } = 1;
        /// <summary>حجم الصفحة</summary>
        public int PageSize { get; set; } = 10;
    }
} 