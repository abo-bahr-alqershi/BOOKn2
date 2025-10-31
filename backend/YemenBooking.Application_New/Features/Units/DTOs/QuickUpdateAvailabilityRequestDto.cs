using System;

namespace YemenBooking.Application.Features.Units.DTOs {
    /// <summary>
    /// DTO للتحديث السريع لحالة الإتاحة
    /// Quick update unit availability request DTO
    /// </summary>
    public class QuickUpdateAvailabilityRequestDto
    {
        public string Status { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
} 