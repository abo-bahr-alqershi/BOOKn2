using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Bookings;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Accounting.Services;

namespace YemenBooking.Application.Features.Bookings.Commands.ConfirmBooking;

/// <summary>
/// معالج أمر إكمال الحجز
/// Complete booking command handler
/// </summary>
public class CompleteBookingCommandHandler : IRequestHandler<CompleteBookingCommand, ResultDto<bool>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IValidationService _validationService;
    private readonly IAuditService _auditService;
    private readonly ILogger<CompleteBookingCommandHandler> _logger;
    private readonly IFinancialAccountingService _financialAccountingService;
    private readonly IPaymentRepository _paymentRepository;

    public CompleteBookingCommandHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IValidationService validationService,
        IAuditService auditService,
        ILogger<CompleteBookingCommandHandler> logger,
        IFinancialAccountingService financialAccountingService,
        IPaymentRepository paymentRepository)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _validationService = validationService;
        _auditService = auditService;
        _logger = logger;
        _financialAccountingService = financialAccountingService;
        _paymentRepository = paymentRepository;
    }

    public async Task<ResultDto<bool>> Handle(CompleteBookingCommand request, CancellationToken cancellationToken)
    {
        try
        {
            var validation = await _validationService.ValidateAsync(request, cancellationToken);
            if (!validation.IsValid)
            {
                return ResultDto<bool>.Failed(validation.Errors.Select(e => e.Message).ToArray());
            }

            var booking = await _unitOfWork.Repository<Booking>().GetByIdAsync(request.BookingId, cancellationToken);
            if (booking == null)
            {
                return ResultDto<bool>.Failed("الحجز غير موجود");
            }

            var finalAmountToPay = booking.FinalAmount > 0 ? booking.FinalAmount : booking.TotalPrice.Amount;
            var totalPaid = await _paymentRepository.GetTotalPaidAmountAsync(booking.Id, cancellationToken);
            var remainingAmount = finalAmountToPay - totalPaid;
            if (remainingAmount > 0)
            {
                return ResultDto<bool>.Failed($"لا يمكن إكمال الحجز قبل سداد كامل المبلغ. المبلغ المتبقي: {remainingAmount}");
            }

            // تنفيذ تحديث حالة الإكمال وتسجيل القيد المحاسبي ضمن ترانزاكشن واحدة
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                // يمكن الإكمال بعد تسجيل المغادرة أو في حالات خاصة
                if (booking.Status != BookingStatus.Completed)
                {
                    booking.Status = BookingStatus.Completed;
                }

                booking.UpdatedAt = DateTime.UtcNow;

                await _unitOfWork.Repository<Booking>().UpdateAsync(booking, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                // حساب المبلغ النهائي (يمكن أن يكون من حقل FinalAmount أو TotalPrice)
                var finalAmount = booking.FinalAmount > 0 ? booking.FinalAmount : booking.TotalPrice.Amount;

                var tx = await _financialAccountingService.RecordBookingCompletionAsync(
                    booking.Id,
                    finalAmount,
                    _currentUserService.UserId);
                if (tx == null)
                    throw new InvalidOperationException("FAILED_TO_RECORD_BOOKING_COMPLETION_TX");
            }, cancellationToken);

            await _auditService.LogAuditAsync(
                entityType: nameof(Booking),
                entityId: booking.Id,
                action: AuditAction.UPDATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { Status = booking.Status.ToString() }),
                performedBy: _currentUserService.UserId,
                notes: $"تم إكمال الحجز بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            return ResultDto<bool>.Succeeded(true, "تم إكمال الحجز بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء إكمال الحجز {BookingId}", request.BookingId);
            return ResultDto<bool>.Failed("حدث خطأ أثناء إكمال الحجز");
        }
    }
}


