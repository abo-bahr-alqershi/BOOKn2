using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.Payments.Services;

namespace YemenBooking.Application.Features.Payments.Commands.Gateways
{
    /// <summary>
    /// معالج أمر الدفع عبر سبأ كاش
    /// SabaCash payment command handler
    /// </summary>
    public class CreateSabaCashPaymentHandler : IRequestHandler<CreateSabaCashPayment, ResultDto<Guid>>
    {
        private readonly IBookingRepository _bookingRepository;
        private readonly IPaymentRepository _paymentRepository;
        private readonly YemenBooking.Application.Features.Payments.Services.IPaymentGatewayService _paymentGatewayService;
        private readonly ICurrentUserService _currentUserService;
        private readonly IFinancialAccountingService _financialAccountingService;
        private readonly ILogger<CreateSabaCashPaymentHandler> _logger;
        private readonly IUnitOfWork _unitOfWork;

        public CreateSabaCashPaymentHandler(
            IBookingRepository bookingRepository,
            IPaymentRepository paymentRepository,
            YemenBooking.Application.Features.Payments.Services.IPaymentGatewayService paymentGatewayService,
            ICurrentUserService currentUserService,
            IFinancialAccountingService financialAccountingService,
            ILogger<CreateSabaCashPaymentHandler> logger,
            IUnitOfWork unitOfWork)
        {
            _bookingRepository = bookingRepository;
            _paymentRepository = paymentRepository;
            _paymentGatewayService = paymentGatewayService;
            _currentUserService = currentUserService;
            _financialAccountingService = financialAccountingService;
            _logger = logger;
            _unitOfWork = unitOfWork;
        }

        public async Task<ResultDto<Guid>> Handle(CreateSabaCashPayment request, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("بدء معالجة دفعة سبأ كاش للحجز {BookingId}", request.BookingId);

                // التحقق من صحة البيانات
                if (request.BookingId == Guid.Empty)
                    return ResultDto<Guid>.Failed("معرف الحجز مطلوب");
                if (request.Amount <= 0)
                    return ResultDto<Guid>.Failed("المبلغ يجب أن يكون أكبر من صفر");
                if (string.IsNullOrWhiteSpace(request.SabaCashTransactionId))
                    return ResultDto<Guid>.Failed("معرف معاملة سبأ كاش مطلوب");

                // التحقق من وجود الحجز
                var booking = await _bookingRepository.GetByIdAsync(request.BookingId, cancellationToken);
                if (booking == null)
                    return ResultDto<Guid>.Failed("الحجز غير موجود");

                // التحقق من حالة الحجز
                if (booking.Status == BookingStatus.Cancelled || booking.Status == BookingStatus.Completed)
                    return ResultDto<Guid>.Failed($"لا يمكن الدفع للحجز في الحالة {booking.Status}");

                // معالجة الدفعة عبر بوابة سبأ كاش
                var gatewayResult = await _paymentGatewayService.ProcessSabaCashPaymentAsync(
                    request.SabaCashTransactionId,
                    request.Amount,
                    cancellationToken);

                if (!gatewayResult.IsSuccess)
                    return ResultDto<Guid>.Failed($"فشل في معالجة دفعة سبأ كاش: {gatewayResult.ErrorMessage}");

                // إنشاء سجل الدفعة
                var payment = new Payment
                {
                    Id = Guid.NewGuid(),
                    BookingId = booking.Id,
                    Amount = new Money(request.Amount, "YER"), // سبأ كاش يستخدم الريال اليمني
                    PaymentMethod = PaymentMethodEnum.EWallet, // المحفظة الإلكترونية
                    TransactionId = request.SabaCashTransactionId,
                    GatewayTransactionId = gatewayResult.TransactionId,
                    Status =  Core.Enums.PaymentStatus.Successful,
                    PaymentDate = DateTime.UtcNow,
                    ProcessedBy = _currentUserService.UserId,
                    ProcessedAt = DateTime.UtcNow,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                await _unitOfWork.ExecuteInTransactionAsync(async () =>
                {
                    await _paymentRepository.AddAsync(payment, cancellationToken);

                    // تحديث حالة الحجز إذا تم دفع المبلغ كاملاً
                    var totalPaid = await _paymentRepository.GetTotalPaidAmountAsync(booking.Id, cancellationToken);
                    var newTotalPaid = totalPaid + request.Amount;
                    if (newTotalPaid >= booking.TotalPrice.Amount)
                    {
                        if (booking.Status == BookingStatus.Pending)
                        {
                            booking.Status = BookingStatus.Confirmed;
                            booking.UpdatedAt = DateTime.UtcNow;
                            await _bookingRepository.UpdateAsync(booking, cancellationToken);
                        }
                    }

                    await _unitOfWork.SaveChangesAsync(cancellationToken);

                    // تسجيل القيد المحاسبي: دفع إلكتروني عبر سبأ كاش
                    var tx = await _financialAccountingService.RecordPaymentTransactionAsync(
                        payment.Id,
                        _currentUserService.UserId);
                    if (tx == null)
                        throw new InvalidOperationException("FAILED_TO_RECORD_SABACASH_PAYMENT_TX");
                }, cancellationToken);

                _logger.LogInformation("تمت معالجة دفعة سبأ كاش بنجاح. PaymentId: {PaymentId}", payment.Id);
                return ResultDto<Guid>.Succeeded(payment.Id, "تمت معالجة دفعة سبأ كاش بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في معالجة دفعة سبأ كاش للحجز {BookingId}", request.BookingId);
                return ResultDto<Guid>.Failed("حدث خطأ أثناء معالجة دفعة سبأ كاش");
            }
        }
    }
}
