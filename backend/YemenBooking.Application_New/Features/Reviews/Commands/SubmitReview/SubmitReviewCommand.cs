using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reviews;

namespace YemenBooking.Application.Features.Reviews.Commands.SubmitReview;

/// <summary>
/// أمر إرسال مراجعة جديدة
/// Command to submit new review
/// </summary>
public class SubmitReviewCommand : IRequest<ResultDto<SubmitReviewResponse>>
{
    /// <summary>
    /// معرف الحجز
    /// </summary>
    public Guid BookingId { get; set; }
    
    /// <summary>
    /// معرف الكيان
    /// </summary>
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// تقييم النظافة (1-5)
    /// </summary>
    public int Cleanliness { get; set; }
    
    /// <summary>
    /// تقييم الخدمة (1-5)
    /// </summary>
    public int Service { get; set; }
    
    /// <summary>
    /// تقييم الموقع (1-5)
    /// </summary>
    public int Location { get; set; }
    
    /// <summary>
    /// تقييم القيمة (1-5)
    /// </summary>
    public int Value { get; set; }
    
    /// <summary>
    /// تعليق المراجعة
    /// </summary>
    public string Comment { get; set; } = string.Empty;
    
    /// <summary>
    /// الصور المرفقة (Base64)
    /// </summary>
    public List<string> ImagesBase64 { get; set; } = new();
}

/// <summary>
/// استجابة إرسال المراجعة
/// </summary>
public class SubmitReviewResponse
{
    /// <summary>
    /// معرف المراجعة الجديدة
    /// </summary>
    public Guid ReviewId { get; set; }
    
    /// <summary>
    /// نجاح الإرسال
    /// </summary>
    public bool Success { get; set; }
    
    /// <summary>
    /// رسالة النتيجة
    /// </summary>
    public string Message { get; set; } = string.Empty;
}