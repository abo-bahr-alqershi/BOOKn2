using System;

namespace YemenBooking.Application.Features.Reviews.DTOs {
    /// <summary>
    /// DTO لردود التقييمات
    /// Review response DTO
    /// </summary>
    public class ReviewResponseDto
    {
        public Guid Id { get; set; }
        public Guid ReviewId { get; set; }
        public string ResponseText { get; set; } = string.Empty;
        public Guid RespondedBy { get; set; }
        public string RespondedByName { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}

