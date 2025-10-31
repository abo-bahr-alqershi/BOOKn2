using System;
using System.Text.Json.Serialization;

namespace YemenBooking.Application.Features.Units.DTOs {
    /// <summary>
    /// DTO لتفاصيل إتاحة الوحدة
    /// DTO for unit availability details
    /// </summary>
    public class UnitAvailabilityDetailDto
    {
        public Guid AvailabilityId { get; set; }

        public Guid UnitId { get; set; }

        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        /// <summary>
        /// وقت بداية التوفر
        /// Start time of availability
        /// </summary>
        public TimeSpan? StartTime { get; set; }
        /// <summary>
        /// وقت نهاية التوفر
        /// End time of availability
        /// </summary>
        public TimeSpan? EndTime { get; set; }
        public string Status { get; set; }

        public string? Reason { get; set; }

        public string? Notes { get; set; }

        public string CreatedBy { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
} 