using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Services.Commands.UpdateProperty;

/// <summary>
/// أمر لتحديث بيانات الخدمة
/// Command to update service information
/// </summary>
public class UpdatePropertyServiceCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الخدمة
    /// Service ID
    /// </summary>
    public Guid ServiceId { get; set; }

    /// <summary>
    /// اسم الخدمة المحدث
    /// Updated service name
    /// </summary>
    public string? Name { get; set; }

    /// <summary>
    /// أيقونة الخدمة
    /// Service icon
    /// </summary>
    public string Icon { get; set; } = string.Empty;


    /// <summary>
    /// سعر الخدمة المحدث
    /// Updated service price
    /// </summary>
    public MoneyDto? Price { get; set; }

    /// <summary>
    /// نموذج التسعير المحدث
    /// Updated pricing model
    /// </summary>
    public PricingModel? PricingModel { get; set; }

        /// <summary>
        /// الوصف المحدث
        /// Updated description
        /// </summary>
        public string? Description { get; set; }
}