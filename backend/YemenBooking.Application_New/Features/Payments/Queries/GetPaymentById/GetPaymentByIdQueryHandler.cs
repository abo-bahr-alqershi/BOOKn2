using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Payments.DTOs;

namespace YemenBooking.Application.Features.Payments.Queries.GetPaymentById
{
    /// <summary>
    /// معالج استعلام جلب تفاصيل دفعة واحدة
    /// Handler for getting a single payment by ID
    /// </summary>
    public class GetPaymentByIdQueryHandler : IRequestHandler<GetPaymentByIdQuery, PaymentDetailsDto>
    {
        private readonly IPaymentRepository _paymentRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;
        private readonly ILogger<GetPaymentByIdQueryHandler> _logger;

        public GetPaymentByIdQueryHandler(
            IPaymentRepository paymentRepository,
            ICurrentUserService currentUserService,
            IMapper _mapper,
            ILogger<GetPaymentByIdQueryHandler> logger)
        {
            _paymentRepository = paymentRepository;
            _currentUserService = currentUserService;
            this._mapper = _mapper;
            _logger = logger;
        }

        public async Task<PaymentDetailsDto> Handle(GetPaymentByIdQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("Processing GetPaymentByIdQuery for PaymentId: {PaymentId}", request.PaymentId);

            // Authorization: Admin or Owner
            var isAdmin = await _currentUserService.IsInRoleAsync("Admin");
            var isOwner = await _currentUserService.IsInRoleAsync("Owner");
            if (!isAdmin && !isOwner)
                throw new UnauthorizedAccessException("ليس لديك صلاحية لعرض تفاصيل الدفعة");

            // Get payment with related data
            var payment = await _paymentRepository.GetQueryable()
                .AsNoTracking()
                .Include(p => p.Booking)
                    .ThenInclude(b => b.Unit)
                        .ThenInclude(u => u.Property)
                .Include(p => p.Booking)
                    .ThenInclude(b => b.User)
                .FirstOrDefaultAsync(p => p.Id == request.PaymentId, cancellationToken);

            if (payment == null)
            {
                _logger.LogWarning("Payment not found: {PaymentId}", request.PaymentId);
                throw new KeyNotFoundException($"الدفعة غير موجودة / Payment not found");
            }

            // If Owner (and NOT Admin), enforce scoping by current user's property
            if (!isAdmin && isOwner)
            {
                var ownerPropId = _currentUserService.PropertyId;
                if (!ownerPropId.HasValue)
                    throw new UnauthorizedAccessException("لا يوجد عقار مرتبط بحساب المالك");
                var paymentPropertyId = payment.Booking?.Unit?.Property?.Id;
                if (!paymentPropertyId.HasValue || paymentPropertyId.Value != ownerPropId.Value)
                    throw new UnauthorizedAccessException("ليست لديك صلاحية لعرض هذه الدفعة");
            }

            // Map to DTO
            var paymentDto = _mapper.Map<PaymentDto>(payment);

            // Localize output dates
            paymentDto.PaymentDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(paymentDto.PaymentDate);
            if (paymentDto.ProcessedAt.HasValue)
                paymentDto.ProcessedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(paymentDto.ProcessedAt.Value);
            if (paymentDto.RefundDeadline.HasValue)
                paymentDto.RefundDeadline = await _currentUserService.ConvertFromUtcToUserLocalAsync(paymentDto.RefundDeadline.Value);
            if (paymentDto.RefundedAt.HasValue)
                paymentDto.RefundedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(paymentDto.RefundedAt.Value);
            if (paymentDto.VoidedAt.HasValue)
                paymentDto.VoidedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(paymentDto.VoidedAt.Value);

            // Build Refunds list
            var refunds = new List<RefundDto>();
            // Check if payment has refund status
            if (payment.Status == YemenBooking.Core.Enums.PaymentStatus.Refunded || 
                payment.Status == YemenBooking.Core.Enums.PaymentStatus.PartiallyRefunded)
            {
                // For now, return empty list - refunds will be tracked separately in future
                // TODO: Implement separate Refunds table
            }

            // Build Activities list
            var activities = new List<PaymentActivityDto>();
            
            // Created activity
            activities.Add(new PaymentActivityDto
            {
                Id = Guid.NewGuid().ToString(),
                Action = "Created",
                Description = "تم إنشاء الدفعة",
                Timestamp = await _currentUserService.ConvertFromUtcToUserLocalAsync(payment.PaymentDate),
                UserId = payment.Booking?.UserId.ToString(),
                UserName = payment.Booking?.User?.Name ?? "Guest"
            });

            // Processed activity
            if (payment.ProcessedAt.HasValue)
            {
                activities.Add(new PaymentActivityDto
                {
                    Id = Guid.NewGuid().ToString(),
                    Action = "Processed",
                    Description = "تمت معالجة الدفعة",
                    Timestamp = await _currentUserService.ConvertFromUtcToUserLocalAsync(payment.ProcessedAt.Value),
                    UserId = payment.ProcessedBy.ToString(),
                    UserName = "System"
                });
            }

            // Status-based activities
            if (payment.Status == YemenBooking.Core.Enums.PaymentStatus.Refunded || 
                payment.Status == YemenBooking.Core.Enums.PaymentStatus.PartiallyRefunded)
            {
                activities.Add(new PaymentActivityDto
                {
                    Id = Guid.NewGuid().ToString(),
                    Action = "Refunded",
                    Description = $"تم استرداد المبلغ - {payment.Status}",
                    Timestamp = await _currentUserService.ConvertFromUtcToUserLocalAsync(payment.UpdatedAt),
                    UserName = "System"
                });
            }

            if (payment.Status == YemenBooking.Core.Enums.PaymentStatus.Voided)
            {
                activities.Add(new PaymentActivityDto
                {
                    Id = Guid.NewGuid().ToString(),
                    Action = "Voided",
                    Description = "تم إلغاء الدفعة",
                    Timestamp = await _currentUserService.ConvertFromUtcToUserLocalAsync(payment.UpdatedAt),
                    UserName = "System"
                });
            }

            // Build BookingInfo
            BookingInfoDto? bookingInfo = null;
            if (payment.Booking != null)
            {
                bookingInfo = new BookingInfoDto
                {
                    BookingId = payment.Booking.Id.ToString(),
                    BookingReference = $"BK-{payment.Booking.Id.ToString().Substring(0, 8).ToUpper()}",
                    CheckIn = await _currentUserService.ConvertFromUtcToUserLocalAsync(payment.Booking.CheckIn),
                    CheckOut = await _currentUserService.ConvertFromUtcToUserLocalAsync(payment.Booking.CheckOut),
                    UnitName = payment.Booking.Unit?.Name ?? "N/A",
                    PropertyName = payment.Booking.Unit?.Property?.Name ?? "N/A",
                    GuestsCount = payment.Booking.GuestsCount
                };
            }

            // Build GatewayInfo
            PaymentGatewayInfoDto? gatewayInfo = null;
            if (!string.IsNullOrEmpty(payment.GatewayTransactionId))
            {
                gatewayInfo = new PaymentGatewayInfoDto
                {
                    GatewayName = payment.PaymentMethod.ToString(),
                    GatewayTransactionId = payment.GatewayTransactionId,
                    AuthorizationCode = payment.GatewayTransactionId,
                    ResponseCode = payment.Status.ToString(),
                    ResponseMessage = $"Payment {payment.Status}"
                };
            }

            return new PaymentDetailsDto
            {
                Payment = paymentDto,
                Refunds = refunds,
                Activities = activities.OrderByDescending(a => a.Timestamp).ToList(),
                BookingInfo = bookingInfo,
                GatewayInfo = gatewayInfo
            };
        }
    }
}
