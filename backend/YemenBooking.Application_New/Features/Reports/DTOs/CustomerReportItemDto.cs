using System;

namespace YemenBooking.Application.Features.Reports.DTOs {
    /// <summary>
    /// عنصر تقرير العملاء
    /// Customer report item
    /// </summary>
    public class CustomerReportItemDto
    {
        /// <summary>
        /// معرف المستخدم
        /// User identifier
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// اسم العميل
        /// Customer name
        /// </summary>
        public string CustomerName { get; set; }

        /// <summary>
        /// عدد الحجوزات
        /// Bookings count
        /// </summary>
        public int BookingsCount { get; set; }

        /// <summary>
        /// إجمالي الإنفاق
        /// Total spent
        /// </summary>
        public decimal TotalSpent { get; set; }
    }
} 