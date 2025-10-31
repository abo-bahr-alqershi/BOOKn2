using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Notifications.Services;

namespace YemenBooking.Application.Features.Reviews.Commands.SubmitReview;

/// <summary>
/// معالج أمر إرسال مراجعة جديدة
/// Handler for submit review command
/// </summary>
public class SubmitReviewCommandHandler : IRequestHandler<SubmitReviewCommand, ResultDto<SubmitReviewResponse>>
{
    private readonly IReviewRepository _reviewRepository;
    private readonly IBookingRepository _bookingRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IFileUploadService _fileUploadService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<SubmitReviewCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

    /// <summary>
    /// منشئ معالج أمر إرسال مراجعة جديدة
    /// Constructor for submit review command handler
    /// </summary>
    /// <param name="reviewRepository">مستودع المراجعات</param>
    /// <param name="bookingRepository">مستودع الحجوزات</param>
    /// <param name="propertyRepository">مستودع العقارات</param>
    /// <param name="fileUploadService">خدمة رفع الملفات</param>
    /// <param name="notificationService">خدمة التنبيهات</param>
    /// <param name="logger">مسجل الأحداث</param>
    public SubmitReviewCommandHandler(
        IReviewRepository reviewRepository,
        IBookingRepository bookingRepository,
        IPropertyRepository propertyRepository,
        IFileUploadService fileUploadService,
        INotificationService notificationService,
        ILogger<SubmitReviewCommandHandler> logger,
        IAuditService auditService,
        ICurrentUserService currentUserService)
    {
        _reviewRepository = reviewRepository;
        _bookingRepository = bookingRepository;
        _propertyRepository = propertyRepository;
        _fileUploadService = fileUploadService;
        _notificationService = notificationService;
        _logger = logger;
        _auditService = auditService;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة أمر إرسال مراجعة جديدة
    /// Handle submit review command
    /// </summary>
    /// <param name="request">طلب إرسال المراجعة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<SubmitReviewResponse>> Handle(SubmitReviewCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء عملية إرسال مراجعة للحجز: {BookingId} والعقار: {PropertyId}", 
                request.BookingId, request.PropertyId);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // البحث عن الحجز والتحقق من صحته
            var booking = await _bookingRepository.GetByIdAsync(request.BookingId, cancellationToken);
            if (booking == null)
            {
                _logger.LogWarning("لم يتم العثور على الحجز: {BookingId}", request.BookingId);
                return ResultDto<SubmitReviewResponse>.Failed("الحجز غير موجود", "BOOKING_NOT_FOUND");
            }

            // التحقق من أن الحجز مكتمل
            if (booking.Status != BookingStatus.Completed)
            {
                _logger.LogWarning("محاولة مراجعة حجز غير مكتمل: {BookingId}, Status: {Status}", 
                    request.BookingId, booking.Status);
                return ResultDto<SubmitReviewResponse>.Failed("يمكن مراجعة الحجوزات المكتملة فقط", "BOOKING_NOT_COMPLETED");
            }

            // التحقق من تطابق العقار مع الحجز (من خلال الوحدة)
            if (booking.Unit?.PropertyId != request.PropertyId)
            {
                _logger.LogWarning("عدم تطابق العقار مع الحجز. BookingPropertyId: {BookingPropertyId}, RequestPropertyId: {RequestPropertyId}", 
                    booking.Unit?.PropertyId, request.PropertyId);
                return ResultDto<SubmitReviewResponse>.Failed("العقار غير متطابق مع الحجز", "PROPERTY_MISMATCH");
            }

            // التحقق من عدم وجود مراجعة مسبقة للحجز
            var existingReviews = await _reviewRepository.GetAllAsync(cancellationToken);
            var existingReview = existingReviews?.FirstOrDefault(r => r.BookingId == request.BookingId);
            if (existingReview != null)
            {
                _logger.LogWarning("يوجد مراجعة مسبقة للحجز: {BookingId}", request.BookingId);
                return ResultDto<SubmitReviewResponse>.Failed("تم إرسال مراجعة لهذا الحجز مسبقاً", "REVIEW_ALREADY_EXISTS");
            }

            // التحقق من وجود العقار
            var property = await _propertyRepository.GetByIdAsync(request.PropertyId, cancellationToken);
            if (property == null)
            {
                _logger.LogWarning("لم يتم العثور على العقار: {PropertyId}", request.PropertyId);
                return ResultDto<SubmitReviewResponse>.Failed("العقار غير موجود", "PROPERTY_NOT_FOUND");
            }

            // رفع الصور المرفقة
            var uploadedImageUrls = await UploadReviewImages(request.ImagesBase64, request.BookingId, cancellationToken);

            // حساب التقييم الإجمالي
            var overallRating = (request.Cleanliness + request.Service + request.Location + request.Value) / 4.0m;

            // إنشاء المراجعة
            var review = new YemenBooking.Core.Entities.Review
            {
                Id = Guid.NewGuid(),
                BookingId = request.BookingId,
                PropertyId = request.PropertyId,
                Cleanliness = request.Cleanliness,
                Service = request.Service,
                Location = request.Location,
                Value = request.Value,
                AverageRating = overallRating,
                Comment = request.Comment.Trim(),
                CreatedAt = DateTime.UtcNow,
                IsPendingApproval = true // تحتاج موافقة الإدارة
            };

            // حفظ المراجعة
            var createResult = await _reviewRepository.AddAsync(review, cancellationToken);
            if (createResult == null)
            {
                _logger.LogError("فشل في حفظ المراجعة للحجز: {BookingId}", request.BookingId);
                
                // حذف الصور المرفوعة في حالة فشل حفظ المراجعة
                await DeleteUploadedImages(uploadedImageUrls, cancellationToken);
                
                return ResultDto<SubmitReviewResponse>.Failed("فشل في حفظ المراجعة", "SAVE_FAILED");
            }

            _logger.LogInformation("تم إنشاء المراجعة بنجاح للعقار: {PropertyId}", request.PropertyId);

            _logger.LogInformation("تم إنشاء المراجعة بنجاح: {ReviewId}", review.Id);

            // ملاحظة: يمكن إضافة إرسال تنبيه للإدارة لاحقاً
            // Note: Admin notification can be added later
            _logger.LogInformation("تمت المراجعة وهي في انتظار الموافقة: {ReviewId}", review.Id);

            _logger.LogInformation("تم إرسال المراجعة بنجاح: {ReviewId} للحجز: {BookingId}", 
                review.Id, request.BookingId);

            // تدقيق يدوي: إرسال مراجعة
            var performerName = _currentUserService.Username;
            var performerId = _currentUserService.UserId;
            var notes = $"تم إرسال مراجعة للعقار {request.PropertyId} (حجز {request.BookingId}) بواسطة {performerName} (ID={performerId})";
            await _auditService.LogAuditAsync(
                entityType: "Review",
                entityId: review.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: JsonSerializer.Serialize(new { review.Id, request.PropertyId, request.BookingId, overallRating }),
                performedBy: performerId,
                notes: notes,
                cancellationToken: cancellationToken);

            var response = new SubmitReviewResponse
            {
                ReviewId = review.Id,
                Success = true,
                Message = "تم إرسال المراجعة بنجاح. سيتم نشرها بعد مراجعتها من قبل فريق الإدارة"
            };

            return ResultDto<SubmitReviewResponse>.Ok(response, "تم إرسال المراجعة بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء إرسال المراجعة للحجز: {BookingId}", request.BookingId);
            return ResultDto<SubmitReviewResponse>.Failed($"حدث خطأ أثناء إرسال المراجعة: {ex.Message}", "SUBMIT_REVIEW_ERROR");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate the input request
    /// </summary>
    /// <param name="request">طلب المراجعة</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<SubmitReviewResponse> ValidateRequest(SubmitReviewCommand request)
    {
        if (request.BookingId == Guid.Empty)
        {
            return ResultDto<SubmitReviewResponse>.Failed("معرف الحجز غير صالح", "INVALID_BOOKING_ID");
        }

        if (request.PropertyId == Guid.Empty)
        {
            return ResultDto<SubmitReviewResponse>.Failed("معرف العقار غير صالح", "INVALID_PROPERTY_ID");
        }

        // التحقق من التقييمات (يجب أن تكون بين 1 و 5)
        var ratings = new[] { request.Cleanliness, request.Service, request.Location, request.Value };
        if (ratings.Any(r => r < 1 || r > 5))
        {
            return ResultDto<SubmitReviewResponse>.Failed("التقييمات يجب أن تكون بين 1 و 5", "INVALID_RATINGS");
        }

        // التحقق من التعليق
        if (string.IsNullOrWhiteSpace(request.Comment))
        {
            return ResultDto<SubmitReviewResponse>.Failed("تعليق المراجعة مطلوب", "COMMENT_REQUIRED");
        }

        if (request.Comment.Length < 10 || request.Comment.Length > 1000)
        {
            return ResultDto<SubmitReviewResponse>.Failed("تعليق المراجعة يجب أن يكون بين 10 و 1000 حرف", "INVALID_COMMENT_LENGTH");
        }

        // التحقق من عدد الصور (حد أقصى 5 صور)
        if (request.ImagesBase64.Count > 5)
        {
            return ResultDto<SubmitReviewResponse>.Failed("يمكن رفع 5 صور كحد أقصى", "TOO_MANY_IMAGES");
        }

        // التحقق من صحة تنسيق الصور
        foreach (var imageBase64 in request.ImagesBase64)
        {
            if (string.IsNullOrWhiteSpace(imageBase64))
            {
                return ResultDto<SubmitReviewResponse>.Failed("تنسيق الصورة غير صالح", "INVALID_IMAGE_FORMAT");
            }

            try
            {
                var imageBytes = Convert.FromBase64String(imageBase64);
                if (imageBytes.Length > 5 * 1024 * 1024) // 5 ميجابايت
                {
                    return ResultDto<SubmitReviewResponse>.Failed("حجم الصورة يجب أن يكون أقل من 5 ميجابايت", "IMAGE_TOO_LARGE");
                }
            }
            catch (FormatException)
            {
                return ResultDto<SubmitReviewResponse>.Failed("تنسيق الصورة غير صحيح", "INVALID_IMAGE_FORMAT");
            }
        }

        return ResultDto<SubmitReviewResponse>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// رفع صور المراجعة
    /// Upload review images
    /// </summary>
    /// <param name="imagesBase64">الصور بتنسيق Base64</param>
    /// <param name="bookingId">معرف الحجز</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة روابط الصور المرفوعة</returns>
    private async Task<List<string>> UploadReviewImages(List<string> imagesBase64, Guid bookingId, CancellationToken cancellationToken)
    {
        var uploadedUrls = new List<string>();

        for (int i = 0; i < imagesBase64.Count; i++)
        {
            try
            {
                var imageBytes = Convert.FromBase64String(imagesBase64[i]);
                var fileName = $"review_{bookingId}_{i + 1}_{DateTime.UtcNow:yyyyMMddHHmmss}";
                
                using var imageStream = new MemoryStream(imageBytes);
                var uploadResult = await _fileUploadService.UploadImageAsync(imageStream, fileName, folder: "reviews");
                var isSuccess = !string.IsNullOrEmpty(uploadResult);
                var fileUrl = uploadResult;
                
                if (isSuccess)
                {
                    uploadedUrls.Add(fileUrl);
                    _logger.LogInformation("تم رفع صورة المراجعة: {FileName}", fileName);
                }
                else
                {
                    _logger.LogWarning("فشل في رفع صورة المراجعة: {FileName}", fileName);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في رفع صورة المراجعة رقم: {ImageIndex}", i + 1);
            }
        }

        return uploadedUrls;
    }

    /// <summary>
    /// حذف الصور المرفوعة
    /// Delete uploaded images
    /// </summary>
    /// <param name="imageUrls">روابط الصور</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    private async Task DeleteUploadedImages(List<string> imageUrls, CancellationToken cancellationToken)
    {
        foreach (var imageUrl in imageUrls)
        {
            try
            {
                await _fileUploadService.DeleteFileAsync(imageUrl);
                _logger.LogInformation("تم حذف صورة المراجعة: {ImageUrl}", imageUrl);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل في حذف صورة المراجعة: {ImageUrl}", imageUrl);
            }
        }
    }
}
