using MediatR;

namespace YemenBooking.Application.Features.Reports.Commands.SubmitFeedback;

/// <summary>
/// أمر إرسال تعليقات أو اقتراحات من المستخدم
/// Command to submit user feedback or suggestions
/// </summary>
public class SubmitFeedbackCommand : IRequest<SubmitFeedbackResponse>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// نوع التعليق (اقتراح، شكوى، مشكلة تقنية، أخرى)
    /// </summary>
    public string FeedbackType { get; set; } = string.Empty;
    
    /// <summary>
    /// الموضوع
    /// </summary>
    public string Subject { get; set; } = string.Empty;
    
    /// <summary>
    /// محتوى التعليق
    /// </summary>
    public string Content { get; set; } = string.Empty;
    
    /// <summary>
    /// معلومات الجهاز (نوع الجهاز، نظام التشغيل، إصدار التطبيق)
    /// </summary>
    public DeviceInfoDto? DeviceInfo { get; set; }
    
    /// <summary>
    /// لقطات الشاشة المرفقة (Base64)
    /// </summary>
    public List<string> ScreenshotsBase64 { get; set; } = new();
}

/// <summary>
/// معلومات الجهاز
/// </summary>
public class DeviceInfoDto
{
    /// <summary>
    /// نوع الجهاز
    /// </summary>
    public string DeviceType { get; set; } = string.Empty;
    
    /// <summary>
    /// نظام التشغيل
    /// </summary>
    public string OperatingSystem { get; set; } = string.Empty;
    
    /// <summary>
    /// إصدار نظام التشغيل
    /// </summary>
    public string OsVersion { get; set; } = string.Empty;
    
    /// <summary>
    /// إصدار التطبيق
    /// </summary>
    public string AppVersion { get; set; } = string.Empty;
}

/// <summary>
/// استجابة إرسال التعليق
/// </summary>
public class SubmitFeedbackResponse
{
    /// <summary>
    /// نجاح الإرسال
    /// </summary>
    public bool Success { get; set; }
    
    /// <summary>
    /// رقم مرجعي للتعليق
    /// </summary>
    public string? ReferenceNumber { get; set; }
    
    /// <summary>
    /// رسالة النتيجة
    /// </summary>
    public string Message { get; set; } = string.Empty;
}