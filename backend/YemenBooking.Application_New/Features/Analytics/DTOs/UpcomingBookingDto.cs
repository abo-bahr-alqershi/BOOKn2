using System;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    public class UpcomingBookingDto
    {
        public Guid BookingId { get; set; }
        public string GuestName { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Status { get; set; }
        public decimal TotalAmount { get; set; }
    }
} 