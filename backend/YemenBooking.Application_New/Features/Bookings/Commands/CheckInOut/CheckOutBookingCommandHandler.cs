using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Bookings;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;

namespace YemenBooking.Application.Features.Bookings.Commands.CheckInOut;

/// <summary>
/// معالج أمر تسجيل المغادرة
/// Check-out booking command handler
/// </summary>
public class CheckOutBookingCommandHandler : IRequestHandler<CheckOutBookingCommand, ResultDto<bool>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IValidationService _validationService;
    private readonly IAuditService _auditService;
    private readonly ILogger<CheckOutBookingCommandHandler> _logger;
    private readonly IFinancialAccountingService _financialAccountingService;
    private readonly IPaymentRepository _paymentRepository;

    public CheckOutBookingCommandHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IValidationService validationService,
        IAuditService auditService,
        ILogger<CheckOutBookingCommandHandler> logger,
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

    public async Task<ResultDto<bool>> Handle(CheckOutBookingCommand request, CancellationToken cancellationToken)
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

            if (booking.Status != BookingStatus.CheckedIn)
            {
                return ResultDto<bool>.Failed("لا يمكن تسجيل المغادرة إلا لحجز في حالة تم الوصول");
            }

            // التحقق من تاريخ التنفيذ وفق توقيت المستخدم
            var userNowLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow);
            var checkInLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(booking.CheckIn);
            if (userNowLocal.Date < checkInLocal.Date)
            {
                return ResultDto<bool>.Failed("لا يمكن تسجيل المغادرة قبل تاريخ الوصول المحدد");
            }

            // لا يسمح بتسجيل المغادرة قبل تسجيل الوصول الفعلي إن وُجد شرط عمل بذلك
            if (booking.ActualCheckInDate.HasValue)
            {
                var actualCheckInLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(booking.ActualCheckInDate.Value);
                if (userNowLocal < actualCheckInLocal)
                {
                    return ResultDto<bool>.Failed("لا يمكن تسجيل المغادرة قبل وقت تسجيل الوصول الفعلي");
                }
            }

            var finalAmountToPay = booking.FinalAmount > 0 ? booking.FinalAmount : booking.TotalPrice.Amount;
            var totalPaid = await _paymentRepository.GetTotalPaidAmountAsync(booking.Id, cancellationToken);
            var remainingAmount = finalAmountToPay - totalPaid;
            if (remainingAmount > 0)
            {
                return ResultDto<bool>.Failed($"لا يمكن إكمال الحجز أثناء تسجيل المغادرة قبل سداد كامل المبلغ. المبلغ المتبقي: {remainingAmount}");
            }

            // تنفيذ التحديث والقيد المحاسبي ضمن ترانزاكشن واحدة
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                booking.Status = BookingStatus.Completed;
                booking.ActualCheckOutDate = await _currentUserService.ConvertFromUserLocalToUtcAsync(userNowLocal);
                booking.UpdatedAt = DateTime.UtcNow;

                await _unitOfWork.Repository<Booking>().UpdateAsync(booking, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                // القيد المحاسبي: تحرير أموال الملاك المعلقة إلى ذمم دائنة - ملاك
                var tx = await _financialAccountingService.RecordCheckoutTransactionAsync(
                    booking.Id,
                    _currentUserService.UserId);
                if (tx == null)
                    throw new InvalidOperationException("FAILED_TO_RECORD_CHECKOUT_TX");
            }, cancellationToken);

            await _auditService.LogAuditAsync(
                entityType: nameof(Booking),
                entityId: booking.Id,
                action: AuditAction.UPDATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { Status = booking.Status.ToString(), ActualCheckOutDate = booking.ActualCheckOutDate }),
                performedBy: _currentUserService.UserId,
                notes: $"تم تسجيل المغادرة بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            return ResultDto<bool>.Succeeded(true, "تم تسجيل المغادرة بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء تسجيل المغادرة للحجز {BookingId}", request.BookingId);
            return ResultDto<bool>.Failed("حدث خطأ أثناء تسجيل المغادرة");
        }
    }
}

