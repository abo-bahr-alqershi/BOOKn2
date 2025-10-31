using System.Collections.Generic;
using YemenBooking.Application.Features.Units.DTOs;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    public class UnitManagementDataDto
    {
        public BaseUnitDto Unit { get; set; }
        public string CurrentAvailability { get; set; }
        public IEnumerable<PricingRuleDto> ActivePricingRules { get; set; }
        public IEnumerable<UpcomingBookingDto> UpcomingBookings { get; set; }
        public IEnumerable<AvailabilityCalendarDto> AvailabilityCalendar { get; set; }
    }
} 