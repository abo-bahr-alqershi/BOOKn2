using System;

namespace YemenBooking.Application.Features.Units.DTOs {
    /// <summary>
    /// DTO لإنشاء إتاحة جديدة
    /// Create new unit availability request DTO
    /// </summary>
    public class CreateAvailabilityRequestDto
    {
        public Guid UnitId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public TimeSpan? StartTime { get; set; }
        public TimeSpan? EndTime { get; set; }
        public string Status { get; set; }
        public string? Reason { get; set; }
        public string? Notes { get; set; }
        public bool? OverrideConflicts { get; set; }
    }
} 