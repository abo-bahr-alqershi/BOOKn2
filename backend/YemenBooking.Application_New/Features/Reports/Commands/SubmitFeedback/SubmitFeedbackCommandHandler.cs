using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Reports.Commands.SubmitFeedback;

/// <summary>
/// معالج أمر إرسال تعليقات المستخدم
/// </summary>
public class SubmitFeedbackCommandHandler : IRequestHandler<SubmitFeedbackCommand, SubmitFeedbackResponse>
{
    private readonly ILogger<SubmitFeedbackCommandHandler> _logger;
    private readonly IEmailService _emailService;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

    public SubmitFeedbackCommandHandler(ILogger<SubmitFeedbackCommandHandler> logger, IEmailService emailService, IAuditService auditService, ICurrentUserService currentUserService)
    {
        _logger = logger;
        _emailService = emailService;
        _auditService = auditService;
        _currentUserService = currentUserService;
    }

    public async Task<SubmitFeedbackResponse> Handle(SubmitFeedbackCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("استلام تعليق جديد من المستخدم {UserId}", request.UserId);

        // TODO: حفظ التعليق في قاعدة البيانات (Feedback table)
        // في الوقت الحالي سنكتفي بإرسال بريد إلى فريق الدعم
        var body = $"نوع: {request.FeedbackType}\nموضوع: {request.Subject}\nمحتوى: {request.Content}";
        await _emailService.SendEmailAsync("support@yemenbooking.com", "تعليق جديد من التطبيق", body, true, cancellationToken);

        // تدقيق يدوي: إرسال تعليق
        var performerName = _currentUserService.Username;
        var performerId = _currentUserService.UserId;
        var notes = $"تم إرسال ملاحظة/تعليق من المستخدم {request.UserId} بواسطة {performerName} (ID={performerId})";
        await _auditService.LogAuditAsync(
            entityType: "Feedback",
            entityId: request.UserId,
            action: AuditAction.CREATE,
            oldValues: null,
            newValues: JsonSerializer.Serialize(new { request.FeedbackType, request.Subject }),
            performedBy: performerId,
            notes: notes,
            cancellationToken: cancellationToken);

        return new SubmitFeedbackResponse
        {
            Success = true,
            ReferenceNumber = Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
            Message = "تم استلام تعليقك، شكرًا لك!"
        };
    }
}
