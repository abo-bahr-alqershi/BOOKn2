using System;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    /// <summary>
    /// نطاق زمني للتواريخ
    /// Date range DTO
    /// </summary>
    public class DateRangeDto
    {
        /// <summary>
        /// تاريخ البداية
        /// Start date
        /// </summary>
        public DateTime StartDate { get; set; }

        /// <summary>
        /// تاريخ النهاية
        /// End date
        /// </summary>
        public DateTime EndDate { get; set; }
    }
} 