using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.SearchAndFilters;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.GetRecommendedProperties;

/// <summary>
/// استعلام الحصول على الكيانات الموصى بها للمستخدم
/// Query to get recommended properties for user
/// </summary>
public class GetRecommendedPropertiesQuery : IRequest<ResultDto<PaginatedResult<PropertySearchResultDto>>>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// عدد الكيانات المطلوبة
    /// </summary>
    public int Count { get; set; } = 5;
    
    /// <summary>
    /// المدينة (اختياري للتوصيات المحلية)
    /// </summary>
    public string? City { get; set; }
}