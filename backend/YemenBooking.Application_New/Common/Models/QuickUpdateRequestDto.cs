using System;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// DTO لتحديث سريع لحالة الإتاحة
    /// Quick update availability request DTO
    /// </summary>
    public class QuickUpdateRequestDto
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Status { get; set; }
    }
} 