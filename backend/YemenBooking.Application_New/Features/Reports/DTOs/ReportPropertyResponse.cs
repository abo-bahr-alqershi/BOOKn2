namespace YemenBooking.Application.Features.Reports.DTOs;

/// <summary>
/// استجابة الإبلاغ عن عقار
/// Report property response
/// </summary>
public class ReportPropertyResponse
{
    /// <summary>
    /// معرف البلاغ
    /// Report ID
    /// </summary>
    public Guid ReportId { get; set; }
    
    /// <summary>
    /// نجاح الإبلاغ
    /// Success status
    /// </summary>
    public bool Success { get; set; }
    
    /// <summary>
    /// رسالة النتيجة
    /// Result message
    /// </summary>
    public string Message { get; set; } = string.Empty;
}
