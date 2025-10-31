using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    public class StatisticsRequestDto
    {
        public IEnumerable<Guid> UnitIds { get; set; }
        public DateRangeRequestDto DateRange { get; set; }
    }
} 