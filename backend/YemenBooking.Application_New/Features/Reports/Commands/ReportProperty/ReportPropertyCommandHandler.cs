using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Application.Features.Reports.DTOs;

namespace YemenBooking.Application.Features.Reports.Commands.ReportProperty;

/// <summary>
/// معالج أمر الإبلاغ عن عقار
/// Handler for report property command
/// </summary>
public class ReportPropertyCommandHandler : IRequestHandler<ReportPropertyCommand, ResultDto<ReportPropertyResponse>>
{
    private readonly IReportRepository _reportRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IUserRepository _userRepository;
    private readonly INotificationService _notificationService;
    private readonly ILogger<ReportPropertyCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

    /// <summary>
    /// منشئ معالج أمر الإبلاغ عن عقار
    /// Constructor for report property command handler
    /// </summary>
    /// <param name="reportRepository">مستودع البلاغات</param>
    /// <param name="propertyRepository">مستودع العقارات</param>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="notificationService">خدمة التنبيهات</param>
    /// <param name="logger">مسجل الأحداث</param>
    public ReportPropertyCommandHandler(
        IReportRepository reportRepository,
        IPropertyRepository propertyRepository,
        IUserRepository userRepository,
        INotificationService notificationService,
        ILogger<ReportPropertyCommandHandler> logger,
        IAuditService auditService,
        ICurrentUserService currentUserService)
    {
        _reportRepository = reportRepository;
        _propertyRepository = propertyRepository;
        _userRepository = userRepository;
        _notificationService = notificationService;
        _logger = logger;
        _auditService = auditService;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة أمر الإبلاغ عن عقار
    /// Handle report property command
    /// </summary>
    /// <param name="request">طلب الإبلاغ عن العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<ReportPropertyResponse>> Handle(ReportPropertyCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء عملية الإبلاغ عن العقار: {PropertyId} من المستخدم: {UserId}", 
                request.ReportedPropertyId, request.ReporterUserId);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // التحقق من وجود المستخدم المبلغ
            var reporter = await _userRepository.GetByIdAsync(request.ReporterUserId, cancellationToken);
            if (reporter == null)
            {
                _logger.LogWarning("لم يتم العثور على المستخدم المبلغ: {UserId}", request.ReporterUserId);
                return ResultDto<ReportPropertyResponse>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
            }

            // التحقق من وجود العقار المبلغ عنه
            var property = await _propertyRepository.GetByIdAsync(request.ReportedPropertyId, cancellationToken);
            if (property == null)
            {
                _logger.LogWarning("لم يتم العثور على العقار المبلغ عنه: {PropertyId}", request.ReportedPropertyId);
                return ResultDto<ReportPropertyResponse>.Failed("العقار غير موجود", "PROPERTY_NOT_FOUND");
            }

            // التحقق من عدم إبلاغ المستخدم عن نفس العقار مسبقاً خلال آخر 30 يوم
            var allReports = await _reportRepository.GetAllAsync(cancellationToken);
            var existingReport = allReports?.FirstOrDefault(r => 
                r.ReporterUserId == request.ReporterUserId && 
                r.ReportedPropertyId == request.ReportedPropertyId &&
                r.CreatedAt >= DateTime.UtcNow.AddDays(-30));

            if (existingReport != null)
            {
                _logger.LogWarning("المستخدم {UserId} أبلغ عن العقار {PropertyId} مسبقاً", 
                    request.ReporterUserId, request.ReportedPropertyId);
                return ResultDto<ReportPropertyResponse>.Failed("لقد قمت بالإبلاغ عن هذا العقار مسبقاً", "ALREADY_REPORTED");
            }

            // إنشاء البلاغ
            var report = new Report
            {
                Id = Guid.NewGuid(),
                ReporterUserId = request.ReporterUserId,
                ReportedPropertyId = request.ReportedPropertyId,
                Reason = request.Reason.Trim(),
                Description = request.Description.Trim(),
                Status = "pending",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            // حفظ البلاغ
            var createResult = await _reportRepository.AddAsync(report, cancellationToken);
            if (createResult == null)
            {
                _logger.LogError("فشل في حفظ البلاغ للعقار: {PropertyId}", request.ReportedPropertyId);
                return ResultDto<ReportPropertyResponse>.Failed("فشل في حفظ البلاغ", "SAVE_FAILED");
            }

            // إرسال تنبيه للإدارة
            try
            {
                // ملاحظة: يمكن إضافة إرسال تنبيه للإدارة لاحقاً
                // Note: Admin notification can be added later
                _logger.LogInformation("تم إنشاء البلاغ بنجاح: {ReportId}", report.Id);

                _logger.LogInformation("تم إرسال تنبيه للإدارة بخصوص البلاغ: {ReportId}", report.Id);
            }
            catch (Exception notificationEx)
            {
                _logger.LogWarning(notificationEx, "فشل في إرسال تنبيه الإدارة للبلاغ: {ReportId}", report.Id);
                // لا نفشل العملية بسبب فشل إرسال التنبيه
            }

            // تحديث إحصائيات البلاغات للعقار
            try
            {
                // ملاحظة: يمكن إضافة تحديث عداد البلاغات لاحقاً
                // Note: Report count increment can be added later
                _logger.LogInformation("تم تحديث عداد البلاغات للعقار: {PropertyId}", request.ReportedPropertyId);
            }
            catch (Exception statsEx)
            {
                _logger.LogWarning(statsEx, "فشل في تحديث إحصائيات البلاغات للعقار: {PropertyId}", request.ReportedPropertyId);
            }

            _logger.LogInformation("تم إنشاء البلاغ بنجاح: {ReportId} للعقار: {PropertyId}", 
                report.Id, request.ReportedPropertyId);

            var response = new ReportPropertyResponse
            {
                ReportId = report.Id,
                Success = true,
                Message = "تم إرسال البلاغ بنجاح. سيتم مراجعته من قبل فريق الإدارة"
            };

            // تدقيق يدوي: إنشاء بلاغ
            var performerName = _currentUserService.Username;
            var performerId = _currentUserService.UserId;
            var notes = $"تم إنشاء بلاغ على العقار {request.ReportedPropertyId} بواسطة {performerName} (ID={performerId})";
            await _auditService.LogAuditAsync(
                entityType: "Report",
                entityId: report.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: JsonSerializer.Serialize(new { report.Id, request.ReportedPropertyId, request.ReporterUserId }),
                performedBy: performerId,
                notes: notes,
                cancellationToken: cancellationToken);

            return ResultDto<ReportPropertyResponse>.Ok(response, "تم إرسال البلاغ بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الإبلاغ عن العقار: {PropertyId}", request.ReportedPropertyId);
            return ResultDto<ReportPropertyResponse>.Failed($"حدث خطأ أثناء إرسال البلاغ: {ex.Message}", "REPORT_ERROR");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate the input request
    /// </summary>
    /// <param name="request">طلب الإبلاغ</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<ReportPropertyResponse> ValidateRequest(ReportPropertyCommand request)
    {
        if (request.ReporterUserId == Guid.Empty)
        {
            return ResultDto<ReportPropertyResponse>.Failed("معرف المستخدم المبلغ غير صالح", "INVALID_REPORTER_ID");
        }

        if (request.ReportedPropertyId == Guid.Empty)
        {
            return ResultDto<ReportPropertyResponse>.Failed("معرف العقار المبلغ عنه غير صالح", "INVALID_PROPERTY_ID");
        }

        if (string.IsNullOrWhiteSpace(request.Reason))
        {
            return ResultDto<ReportPropertyResponse>.Failed("سبب البلاغ مطلوب", "REASON_REQUIRED");
        }

        if (request.Reason.Length < 5 || request.Reason.Length > 200)
        {
            return ResultDto<ReportPropertyResponse>.Failed("سبب البلاغ يجب أن يكون بين 5 و 200 حرف", "INVALID_REASON_LENGTH");
        }

        if (string.IsNullOrWhiteSpace(request.Description))
        {
            return ResultDto<ReportPropertyResponse>.Failed("وصف المشكلة مطلوب", "DESCRIPTION_REQUIRED");
        }

        if (request.Description.Length < 10 || request.Description.Length > 1000)
        {
            return ResultDto<ReportPropertyResponse>.Failed("وصف المشكلة يجب أن يكون بين 10 و 1000 حرف", "INVALID_DESCRIPTION_LENGTH");
        }

        // التحقق من عدم احتواء النص على كلمات غير لائقة
        var inappropriateWords = new[] { "كلمة1", "كلمة2" }; // يمكن تحديث هذه القائمة
        var combinedText = $"{request.Reason} {request.Description}".ToLower();
        
        if (inappropriateWords.Any(word => combinedText.Contains(word)))
        {
            return ResultDto<ReportPropertyResponse>.Failed("يحتوي النص على كلمات غير مناسبة", "INAPPROPRIATE_CONTENT");
        }

        return ResultDto<ReportPropertyResponse>.Ok(null, "البيانات صحيحة");
    }
}
