using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// DTO لطلب تطبيق نسبة مئوية على الأسعار
    /// Apply percentage change request DTO
    /// </summary>
    public class ApplyPercentageRequestDto
    {
        public IEnumerable<Guid> UnitIds { get; set; }
        public decimal PercentageChange { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
} 