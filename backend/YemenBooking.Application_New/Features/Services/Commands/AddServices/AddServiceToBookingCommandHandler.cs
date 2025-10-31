using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Services;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;

namespace YemenBooking.Application.Features.Services.Commands.AddServices
{
    /// <summary>
    /// معالج أمر إضافة خدمة إلى الحجز
    /// </summary>
    public class AddServiceToBookingCommandHandler : IRequestHandler<AddServiceToBookingCommand, ResultDto<bool>>
    {
        private readonly IBookingRepository _bookingRepository;
        private readonly IPropertyServiceRepository _serviceRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<AddServiceToBookingCommandHandler> _logger;
        private readonly IFinancialAccountingService _financialAccountingService;
        private readonly IUnitRepository _unitRepository;
        private readonly ICurrencySettingsService _currencySettingsService;
        private readonly IUnitOfWork _unitOfWork;

        public AddServiceToBookingCommandHandler(
            IBookingRepository bookingRepository,
            IPropertyServiceRepository serviceRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<AddServiceToBookingCommandHandler> logger,
            IFinancialAccountingService financialAccountingService,
            IUnitRepository unitRepository,
            ICurrencySettingsService currencySettingsService,
            IUnitOfWork unitOfWork)
        {
            _bookingRepository = bookingRepository;
            _serviceRepository = serviceRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
            _financialAccountingService = financialAccountingService;
            _unitRepository = unitRepository;
            _currencySettingsService = currencySettingsService;
            _unitOfWork = unitOfWork;
        }

        public async Task<ResultDto<bool>> Handle(AddServiceToBookingCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء إضافة خدمة للحجز: BookingId={BookingId}, ServiceId={ServiceId}, Quantity={Quantity}",
                request.BookingId, request.ServiceId, request.Quantity);

            // التحقق من المدخلات
            if (request.BookingId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الحجز مطلوب");
            if (request.ServiceId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الخدمة مطلوب");
            if (request.Quantity <= 0)
                return ResultDto<bool>.Failed("الكمية يجب أن تكون أكبر من صفر");

            // التحقق من وجود الحجز
            var booking = await _bookingRepository.GetBookingByIdAsync(request.BookingId, cancellationToken);
            if (booking == null)
                return ResultDto<bool>.Failed("الحجز غير موجود");

            // التحقق من وجود الخدمة
            var service = await _serviceRepository.GetServiceByIdAsync(request.ServiceId, cancellationToken);
            if (service == null)
                return ResultDto<bool>.Failed("الخدمة غير موجودة");

            // تحقق من التناسق في العملة بين سعر الخدمة وعملة الحجز
            if (!string.Equals(service.Price.Currency, booking.TotalPrice.Currency, StringComparison.OrdinalIgnoreCase))
                return ResultDto<bool>.Failed($"عملة الخدمة ({service.Price.Currency}) يجب أن تطابق عملة الحجز ({booking.TotalPrice.Currency})");

            // تحقق أن العملة مدعومة في إعدادات النظام
            var currencies = await _currencySettingsService.GetCurrenciesAsync(cancellationToken);
            var isSupported = currencies.Any(c => string.Equals(c.Code, service.Price.Currency, StringComparison.OrdinalIgnoreCase));
            if (!isSupported)
                return ResultDto<bool>.Failed("العملة غير مدعومة في إعدادات النظام");

            // التحقق من الصلاحيات (صاحب الحجز أو مسؤول)
            if (_currentUserService.Role != "Admin"  && booking.UserId != _currentUserService.UserId)
                return ResultDto<bool>.Failed("غير مصرح لك بإضافة خدمة لهذا الحجز");

            // تنفيذ الإضافة + إعادة الحساب + القيد المحاسبي ضمن ترانزاكشن واحدة
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                var added = await _bookingRepository.AddServiceToBookingAsync(request.BookingId, request.ServiceId, request.Quantity, cancellationToken);
                if (!added)
                    throw new InvalidOperationException("FAILED_TO_ADD_SERVICE_TO_BOOKING");

                await _bookingRepository.RecalculatePriceAsync(request.BookingId, cancellationToken);

                var unit = await _unitRepository.GetByIdAsync(booking.UnitId, cancellationToken);
                if (unit != null && service != null)
                {
                    var serviceAmount = service.Price.Amount * request.Quantity;

                    var tx = await _financialAccountingService.RecordAdditionalServiceTransactionAsync(
                        booking.Id,
                        service.Id,
                        serviceAmount,
                        service.Name,
                        _currentUserService.UserId);
                    if (tx == null)
                        throw new InvalidOperationException("FAILED_TO_RECORD_ADDITIONAL_SERVICE_TX");
                }
            }, cancellationToken);

            // تسجيل التدقيق
            await _auditService.LogBusinessOperationAsync(
                "AddServiceToBooking",
                $"تم إضافة الخدمة {request.ServiceId} إلى الحجز {request.BookingId} بكمية {request.Quantity}",
                request.BookingId,
                "BookingService",
                _currentUserService.UserId,
                null,
                cancellationToken);

            _logger.LogInformation("اكتملت عملية إضافة الخدمة إلى الحجز بنجاح");
            return ResultDto<bool>.Succeeded(true, "تم إضافة الخدمة إلى الحجز بنجاح");
        }
    }
} 