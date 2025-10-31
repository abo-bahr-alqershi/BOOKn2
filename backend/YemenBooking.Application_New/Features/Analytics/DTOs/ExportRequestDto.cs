using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    public class ExportRequestDto
    {
        public string Type { get; set; }
        public IEnumerable<Guid>? UnitIds { get; set; }
        public DateRangeRequestDto DateRange { get; set; }
    }
} 