using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Units.Commands.CheckUnitAvailability;

/// <summary>
/// أمر التحقق من توفر الوحدة للعميل
/// Command to check unit availability for client
/// </summary>
public class ClientCheckUnitAvailabilityCommand : IRequest<ResultDto<ClientUnitAvailabilityResponse>>
{
    /// <summary>
    /// معرف الوحدة
    /// Unit ID
    /// </summary>
    public Guid UnitId { get; set; }

    /// <summary>
    /// تاريخ بداية الحجز
    /// Check-in date
    /// </summary>
    public DateTime CheckInDate { get; set; }

    /// <summary>
    /// تاريخ نهاية الحجز
    /// Check-out date
    /// </summary>
    public DateTime CheckOutDate { get; set; }

    /// <summary>
    /// عدد البالغين
    /// Number of adults
    /// </summary>
    public int Adults { get; set; } = 1;

    /// <summary>
    /// عدد الأطفال
    /// Number of children
    /// </summary>
    public int Children { get; set; } = 0;

    /// <summary>
    /// معرف المستخدم (اختياري)
    /// User ID (optional)
    /// </summary>
    public Guid? UserId { get; set; }
}

/// <summary>
/// استجابة توفر الوحدة
/// Unit availability response
/// </summary>
public class ClientUnitAvailabilityResponse
{
    /// <summary>
    /// معرف الوحدة
    /// Unit ID
    /// </summary>
    public Guid UnitId { get; set; }

    /// <summary>
    /// هل الوحدة متاحة
    /// Is unit available
    /// </summary>
    public bool IsAvailable { get; set; }

    /// <summary>
    /// السعر الإجمالي
    /// Total price
    /// </summary>
    public decimal TotalPrice { get; set; }

    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    public string Currency { get; set; } = "YER";

    /// <summary>
    /// السعر لكل ليلة
    /// Price per night
    /// </summary>
    public decimal PricePerNight { get; set; }

    /// <summary>
    /// عدد الليالي
    /// Number of nights
    /// </summary>
    public int NumberOfNights { get; set; }

    /// <summary>
    /// الرسوم الإضافية
    /// Additional fees
    /// </summary>
    public List<ClientAdditionalFeeDto> AdditionalFees { get; set; } = new();

    /// <summary>
    /// الضرائب
    /// Taxes
    /// </summary>
    public decimal TaxAmount { get; set; }

    /// <summary>
    /// سبب عدم التوفر (إذا لم تكن متاحة)
    /// Reason for unavailability (if not available)
    /// </summary>
    public string? UnavailabilityReason { get; set; }

    /// <summary>
    /// التواريخ المتاحة البديلة
    /// Alternative available dates
    /// </summary>
    public List<ClientAlternativeDateDto> AlternativeDates { get; set; } = new();
}

/// <summary>
/// بيانات الرسوم الإضافية
/// Additional fee data
/// </summary>
public class ClientAdditionalFeeDto
{
    /// <summary>
    /// اسم الرسم
    /// Fee name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// المبلغ
    /// Amount
    /// </summary>
    public decimal Amount { get; set; }

    /// <summary>
    /// نوع الرسم
    /// Fee type
    /// </summary>
    public string Type { get; set; } = string.Empty;

    /// <summary>
    /// الوصف
    /// Description
    /// </summary>
    public string? Description { get; set; }
}

/// <summary>
/// بيانات التواريخ البديلة
/// Alternative dates data
/// </summary>
public class ClientAlternativeDateDto
{
    /// <summary>
    /// تاريخ الدخول
    /// Check-in date
    /// </summary>
    public DateTime CheckInDate { get; set; }

    /// <summary>
    /// تاريخ الخروج
    /// Check-out date
    /// </summary>
    public DateTime CheckOutDate { get; set; }

    /// <summary>
    /// السعر لهذه التواريخ
    /// Price for these dates
    /// </summary>
    public decimal Price { get; set; }
}