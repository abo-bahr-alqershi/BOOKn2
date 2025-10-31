namespace YemenBooking.Application.Features.Payments.DTOs;

/// <summary>
/// DTO لحالة الدفع
/// DTO for payment status
/// </summary>
public class PaymentStatusDto
{
    /// <summary>
    /// الحالة
    /// Status
    /// </summary>
    public string Status { get; set; } = string.Empty;
    
    /// <summary>
    /// الرسالة
    /// Message
    /// </summary>
    public string Message { get; set; } = string.Empty;
    
    /// <summary>
    /// التفاصيل
    /// Details
    /// </summary>
    public string Details { get; set; } = string.Empty;
}
