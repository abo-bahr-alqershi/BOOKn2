using System.Collections.Generic;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    public class ManagementPageResponseDto
    {
        public IEnumerable<UnitManagementDataDto> Units { get; set; }
        public ManagementSummaryDto Summary { get; set; }
    }
} 