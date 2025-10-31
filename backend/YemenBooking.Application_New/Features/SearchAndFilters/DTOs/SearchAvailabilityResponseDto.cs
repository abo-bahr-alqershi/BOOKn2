using System;
using System.Collections.Generic;
using YemenBooking.Application.Features.Units.DTOs;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs {
    /// <summary>
    /// Response DTO for availability search
    /// </summary>
    public class SearchAvailabilityResponseDto
    {
        public IEnumerable<UnitAvailabilityDetailDto> Availabilities { get; set; } = new List<UnitAvailabilityDetailDto>();
        public IEnumerable<object> Conflicts { get; set; } = new List<object>();
        public int TotalCount { get; set; }
        public bool HasMore { get; set; }
    }
}