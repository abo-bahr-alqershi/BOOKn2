using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.PropertyTypes.Commands.CreateProperty;

/// <summary>
/// أمر لإنشاء نوع كيان جديد
/// Command to create a new property type
/// </summary>
public class CreatePropertyTypeCommand : IRequest<ResultDto<Guid>>
{
    /// <summary>
    /// اسم نوع الكيان
    /// Property type name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// وصف نوع الكيان
    /// Property type description
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// المرافق الافتراضية لنوع الكيان (JSON)
    /// Default amenities for the property type (JSON)
    /// </summary>
    public string DefaultAmenities { get; set; } = string.Empty;

    /// <summary>
    /// ايقونة لنوع الكيان
    /// Icon for the property type
    /// </summary>
    public string Icon { get; set; } = string.Empty;

} 