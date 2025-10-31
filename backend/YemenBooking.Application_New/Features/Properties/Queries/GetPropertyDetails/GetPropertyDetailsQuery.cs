using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Properties.Queries.GetPropertyDetails;

/// <summary>
/// استعلام الحصول على تفاصيل عقار محدد
/// Query to get property details
/// </summary>
public class GetPropertyDetailsQuery : IRequest<ResultDto<PropertyDetailsDto>>
{
    /// <summary>
    /// معرف الكيان
    /// </summary>
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// معرف المستخدم (لمعرفة حالة المفضلات)
    /// </summary>
    public Guid? UserId { get; set; }

        /// <summary>
    /// تضمين الوحدات الفرعية (اختياري)
    /// IncludeUnits
    /// </summary>
    public bool IncludeUnits { get; set; } = true;

    /// <summary>
    /// تضمين الحقول الديناميكية (اختياري)
    /// Include dynamic fields (optional)
    /// </summary>
    public bool IncludeDynamicFields { get; set; } = true;

}