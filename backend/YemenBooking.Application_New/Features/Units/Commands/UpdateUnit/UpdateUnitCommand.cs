using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.DynamicFields.DTOs;

namespace YemenBooking.Application.Features.Units.Commands.UpdateUnit;

/// <summary>
/// أمر لتحديث بيانات الوحدة
/// Command to update unit information
/// </summary>
public class UpdateUnitCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الوحدة
    /// Unit ID
    /// </summary>
    public Guid UnitId { get; set; }

    /// <summary>
    /// اسم الوحدة المحدث
    /// Updated unit name
    /// </summary>
    public string? Name { get; set; }

    /// <summary>
    /// السعر الأساسي المحدث للوحدة
    /// Updated base price of the unit
    /// </summary>
    public MoneyDto? BasePrice { get; set; }

    /// <summary>
    /// مميزات الوحدة المحدثة
    /// Updated features of the unit
    /// </summary>
    public string? CustomFeatures { get; set; }

    /// <summary>
    /// طريقة حساب السعر المحدثة
    /// Updated pricing calculation method
    /// </summary>
    public PricingMethod? PricingMethod { get; set; }
    
    /// <summary>
    /// قيم الحقول الديناميكية للوحدة
    /// Dynamic field values for the unit
    /// </summary>
    public List<FieldValueDto> FieldValues { get; set; } = new List<FieldValueDto>();

    /// <summary>
    /// الصور المرسلة مؤقتاً للوحدة
    /// </summary>
    public List<string> Images { get; set; } = new List<string>();

    /// <summary>
    /// هل تقبل الوحدة إلغاء الحجز (تحديث اختياري)
    /// </summary>
    public bool? AllowsCancellation { get; set; }

    /// <summary>
    /// عدد أيام نافذة الإلغاء قبل الوصول (تحديث اختياري)
    /// </summary>
    public int? CancellationWindowDays { get; set; }
} 