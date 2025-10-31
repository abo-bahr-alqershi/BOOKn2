using System;

namespace YemenBooking.Application.Features.Units.DTOs {
    /// <summary>
    /// DTO لجدول توفر الوحدة
    /// DTO for unit availability schedule
    /// </summary>
    public class UnitAvailabilityDto
    {
        /// <summary>
        /// معرف الوحدة
        /// Unit identifier
        /// </summary>
        public Guid UnitId { get; set; }

        /// <summary>
        /// تاريخ البداية (اختياري)
        /// Start date (optional)
        /// </summary>
        public DateTime? StartDate { get; set; }

        /// <summary>
        /// تاريخ النهاية (اختياري)
        /// End date (optional)
        /// </summary>
        public DateTime? EndDate { get; set; }

        /// <summary>
        /// اسم الوحدة
        /// Unit name
        /// </summary>
        public string UnitName { get; set; }
    }
} 