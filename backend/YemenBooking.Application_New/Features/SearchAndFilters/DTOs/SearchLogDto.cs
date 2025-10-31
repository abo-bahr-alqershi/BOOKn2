using System;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs {
    /// <summary>
    /// DTO لسجل عمليات البحث
    /// DTO for search logs
    /// </summary>
    public class SearchLogDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string SearchType { get; set; }
        public string CriteriaJson { get; set; }
        public int ResultCount { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public DateTime CreatedAt { get; set; }
    }
} 