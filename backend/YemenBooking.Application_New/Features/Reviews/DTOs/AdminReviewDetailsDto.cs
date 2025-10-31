using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Reviews.DTOs {
    /// <summary>
    /// تفاصيل تقييم شاملة للوحة التحكم الإدارية
    /// Admin review details DTO
    /// </summary>
    public class AdminReviewDetailsDto
    {
        public Guid Id { get; set; }
        public Guid BookingId { get; set; }
        public Guid PropertyId { get; set; }
        public Guid? UnitId { get; set; }

        // Ratings
        public int Cleanliness { get; set; }
        public int Service { get; set; }
        public int Location { get; set; }
        public int Value { get; set; }
        public decimal AverageRating { get; set; }

        // Review content
        public string Comment { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public bool IsApproved { get; set; }
        public bool IsPending { get; set; }
        public string? ResponseText { get; set; }
        public DateTime? ResponseDate { get; set; }
        public Guid? RespondedBy { get; set; }

        // Images
        public List<ReviewImageDto> Images { get; set; } = new List<ReviewImageDto>();

        // Linked names
        public string PropertyName { get; set; } = string.Empty;
        public string? UnitName { get; set; }

        // Property location
        public string? PropertyCity { get; set; }
        public string? PropertyAddress { get; set; }

        // Reviewer
        public string UserName { get; set; } = string.Empty;
        public string? UserEmail { get; set; }
        public string? UserPhone { get; set; }

        // BookingDto details
        public DateTime? BookingCheckIn { get; set; }
        public DateTime? BookingCheckOut { get; set; }
        public int? GuestsCount { get; set; }
        public string? BookingStatus { get; set; }
        public string? BookingSource { get; set; }
    }
}

