using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.SearchLogs
{
    /// <summary>
    /// استعلام لجلب سجلات البحث
    /// Query to get search logs with pagination and filtering
    /// </summary>
    public class GetSearchLogsQuery : IRequest<PaginatedResult<SearchLogDto>>
    {
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
        public Guid? UserId { get; set; }
        public string? SearchType { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }
} 