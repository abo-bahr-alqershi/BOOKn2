using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Payments;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Payments.DTOs;
using YemenBooking.Application.Features;
using PaymentStatus = YemenBooking.Core.Enums.PaymentStatus;

namespace YemenBooking.Application.Features.Payments.Queries.GetPaymentAnalytics
{
    /// <summary>
    /// معالج استعلام جلب تحليلات المدفوعات والإيرادات
    /// Handler for getting payment and revenue analytics query
    /// </summary>
    public class GetPaymentAnalyticsQueryHandler : IRequestHandler<GetPaymentAnalyticsQuery, ResultDto<PaymentAnalyticsDto>>
    {
        private readonly IPaymentRepository _paymentRepository;
        private readonly IBookingRepository _bookingRepository;
        private readonly ICurrencyExchangeRepository _currencyExchangeRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetPaymentAnalyticsQueryHandler> _logger;
        private const string DEFAULT_CURRENCY = "YER";
        private readonly Dictionary<string, decimal> _rateCache = new();

        public GetPaymentAnalyticsQueryHandler(
            IPaymentRepository paymentRepository,
            IBookingRepository bookingRepository,
            ICurrencyExchangeRepository currencyExchangeRepository,
            ICurrentUserService currentUserService,
            ILogger<GetPaymentAnalyticsQueryHandler> logger)
        {
            _paymentRepository = paymentRepository;
            _bookingRepository = bookingRepository;
            _currencyExchangeRepository = currencyExchangeRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ResultDto<PaymentAnalyticsDto>> Handle(GetPaymentAnalyticsQuery request, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("Processing GetPaymentAnalyticsQuery with filters: {@Request}", request);

                // Authorization: Admin or Owner (Owner limited to own property)
                var isAdmin = await _currentUserService.IsInRoleAsync("Admin");
                var isOwner = await _currentUserService.IsInRoleAsync("Owner");
                if (!isAdmin && !isOwner)
                {
                    return ResultDto<PaymentAnalyticsDto>.Failure("ليس لديك صلاحية لعرض تحليلات المدفوعات");
                }

                // If Owner (and NOT Admin), enforce PropertyId scoping (auto-apply if not provided)
                if (!isAdmin && isOwner)
                {
                    var ownerPropId = _currentUserService.PropertyId;
                    if (!ownerPropId.HasValue)
                    {
                        return ResultDto<PaymentAnalyticsDto>.Failure("لا يوجد عقار مرتبط بحساب المالك");
                    }
                    if (request.PropertyId.HasValue && request.PropertyId.Value != ownerPropId.Value)
                    {
                        return ResultDto<PaymentAnalyticsDto>.Failure("ليس لديك صلاحية لعرض تحليلات هذا الكيان");
                    }
                    request.PropertyId = ownerPropId.Value;
                }

                // Set default date range if not provided
                var endDate = request.EndDate ?? DateTime.UtcNow;
                var startDate = request.StartDate ?? endDate.AddDays(-30);

                // Normalize dates to UTC
                startDate = await _currentUserService.ConvertFromUserLocalToUtcAsync(startDate);
                endDate = await _currentUserService.ConvertFromUserLocalToUtcAsync(endDate);

                // Build base query (no Includes to avoid loading navigation graphs)
                var paymentsQuery = _paymentRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(p => p.PaymentDate >= startDate && p.PaymentDate <= endDate);

                // Apply property filter if provided (or enforced for Owner)
                if (request.PropertyId.HasValue)
                {
                    paymentsQuery = paymentsQuery.Where(p => p.Booking.Unit.PropertyId == request.PropertyId.Value);
                }

                var payments = await paymentsQuery.ToListAsync(cancellationToken);

                // Calculate summary
                var summary = await CalculateSummary(payments, startDate, endDate, request.PropertyId, cancellationToken);

                // Calculate trends
                var trends = await CalculateTrends(payments, startDate, endDate, cancellationToken);

                // Calculate method analytics
                var methodAnalytics = await CalculateMethodAnalytics(payments, cancellationToken);

                // Calculate status analytics
                var statusAnalytics = await CalculateStatusAnalytics(payments, cancellationToken);

                // Calculate refund analytics
                var refundAnalytics = await CalculateRefundAnalytics(payments, cancellationToken);

                // Convert all trend dates to user's local time
                foreach (var trend in trends)
                {
                    trend.Date = await _currentUserService.ConvertFromUtcToUserLocalAsync(trend.Date);
                }

                // Convert refund trend dates to user's local time
                foreach (var refundTrend in refundAnalytics.Trends)
                {
                    refundTrend.Date = await _currentUserService.ConvertFromUtcToUserLocalAsync(refundTrend.Date);
                }

                var analyticsDto = new PaymentAnalyticsDto
                {
                    Summary = summary,
                    Trends = trends,
                    MethodAnalytics = methodAnalytics,
                    StatusAnalytics = statusAnalytics,
                    RefundAnalytics = refundAnalytics,
                    StartDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(startDate),
                    EndDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(endDate)
                };

                return ResultDto<PaymentAnalyticsDto>.Ok(analyticsDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing GetPaymentAnalyticsQuery");
                return ResultDto<PaymentAnalyticsDto>.Failure($"حدث خطأ أثناء جلب التحليلات: {ex.Message}");
            }
        }

        private async Task<PaymentSummaryDto> CalculateSummary(
            List<Payment> payments,
            DateTime startDate,
            DateTime endDate,
            Guid? propertyId,
            CancellationToken cancellationToken)
        {
            var successfulPayments = payments.Where(p => p.Status == PaymentStatus.Successful).ToList();
            
            // تحويل جميع المبالغ إلى العملة الافتراضية (YER)
            var totalAmount = await ConvertAllToDefaultCurrency(
                successfulPayments.Select(p => p.Amount).ToList(), 
                cancellationToken);
            
            var totalTransactions = payments.Count;
            var successfulCount = successfulPayments.Count;
            var failedCount = payments.Count(p => p.Status == PaymentStatus.Failed);
            var pendingCount = payments.Count(p => p.Status == PaymentStatus.Pending);
            
            var refundedPayments = payments.Where(p => 
                p.Status == PaymentStatus.Refunded || 
                p.Status == PaymentStatus.PartiallyRefunded).ToList();
            var refundCount = refundedPayments.Count;
            
            var totalRefunded = await ConvertAllToDefaultCurrency(
                refundedPayments.Select(p => p.Amount).ToList(),
                cancellationToken);

            var successRate = totalTransactions > 0 ? (double)successfulCount / totalTransactions * 100 : 0;
            var avgTransactionValue = totalTransactions > 0 ? totalAmount / totalTransactions : 0;

            // Calculate daily, weekly, monthly revenue
            var now = DateTime.UtcNow;
            var todayStart = new DateTime(now.Year, now.Month, now.Day, 0, 0, 0, DateTimeKind.Utc);
            var weekStart = now.AddDays(-7);
            var monthStart = now.AddDays(-30);

            var dailyPayments = payments
                .Where(p => p.Status == PaymentStatus.Successful && p.PaymentDate >= todayStart)
                .Select(p => p.Amount)
                .ToList();
            var dailyRevenue = await ConvertAllToDefaultCurrency(dailyPayments, cancellationToken);

            var weeklyPayments = payments
                .Where(p => p.Status == PaymentStatus.Successful && p.PaymentDate >= weekStart)
                .Select(p => p.Amount)
                .ToList();
            var weeklyRevenue = await ConvertAllToDefaultCurrency(weeklyPayments, cancellationToken);

            var monthlyPayments = payments
                .Where(p => p.Status == PaymentStatus.Successful && p.PaymentDate >= monthStart)
                .Select(p => p.Amount)
                .ToList();
            var monthlyRevenue = await ConvertAllToDefaultCurrency(monthlyPayments, cancellationToken);

            // Calculate growth rate (compare with previous period)
            var periodLength = endDate - startDate;
            var previousStartDate = startDate - periodLength;
            var previousEndDate = startDate;

            var previousPeriodQuery = _paymentRepository.GetQueryable()
                .AsNoTracking()
                .Where(p => p.PaymentDate >= previousStartDate && p.PaymentDate < previousEndDate);

            if (propertyId.HasValue)
            {
                previousPeriodQuery = previousPeriodQuery
                    .Where(p => p.Booking.Unit.PropertyId == propertyId.Value);
            }

            var previousPayments = await previousPeriodQuery
                .Where(p => p.Status == PaymentStatus.Successful)
                .Select(p => p.Amount)
                .ToListAsync(cancellationToken);
            var previousAmount = await ConvertAllToDefaultCurrency(previousPayments, cancellationToken);

            var growthRate = previousAmount > 0 
                ? ((totalAmount - previousAmount) / previousAmount) * 100 
                : totalAmount > 0 ? 100 : 0;

            // Calculate revenue breakdown (bookings vs services)
            // Avoid relying on unloaded navigation properties (Booking)
            var bookingsPayments = successfulPayments
                .Select(p => p.Amount)
                .ToList();
            var bookingsRevenue = await ConvertAllToDefaultCurrency(bookingsPayments, cancellationToken);

            // For services and other revenue, we'll consider them as bookings for now
            // This can be enhanced if there's a separate service payment tracking
            var servicesRevenue = 0m;
            var otherRevenue = 0m;

            return new PaymentSummaryDto
            {
                TotalTransactions = totalTransactions,
                TotalAmount = new MoneyDto
                {
                    Amount = totalAmount,
                    Currency = DEFAULT_CURRENCY,
                    ExchangeRate = 1
                },
                AverageTransactionValue = new MoneyDto
                {
                    Amount = avgTransactionValue,
                    Currency = DEFAULT_CURRENCY,
                    ExchangeRate = 1
                },
                SuccessRate = Math.Round(successRate, 2),
                SuccessfulTransactions = successfulCount,
                FailedTransactions = failedCount,
                PendingTransactions = pendingCount,
                TotalRefunded = new MoneyDto
                {
                    Amount = totalRefunded,
                    Currency = DEFAULT_CURRENCY,
                    ExchangeRate = 1
                },
                RefundCount = refundCount,
                DailyRevenue = dailyRevenue,
                WeeklyRevenue = weeklyRevenue,
                MonthlyRevenue = monthlyRevenue,
                GrowthRate = Math.Round((double)growthRate, 2),
                BookingsRevenue = bookingsRevenue,
                ServicesRevenue = servicesRevenue,
                OtherRevenue = otherRevenue
            };
        }

        private async Task<List<PaymentTrendDto>> CalculateTrends(
            List<Payment> payments,
            DateTime startDate,
            DateTime endDate,
            CancellationToken cancellationToken)
        {
            var trends = new List<PaymentTrendDto>();
            var periodDays = (endDate - startDate).Days;

            // Group by day for periods up to 31 days, otherwise group by week
            var groupByDay = periodDays <= 31;

            if (groupByDay)
            {
                var dailyGroups = payments
                    .GroupBy(p => new DateTime(p.PaymentDate.Year, p.PaymentDate.Month, p.PaymentDate.Day))
                    .OrderBy(g => g.Key);

                foreach (var group in dailyGroups)
                {
                    var groupPayments = group.ToList();
                    var successfulCount = groupPayments.Count(p => p.Status == PaymentStatus.Successful);
                    var totalCount = groupPayments.Count;

                    var groupSuccessfulPayments = groupPayments
                        .Where(p => p.Status == PaymentStatus.Successful)
                        .Select(p => p.Amount)
                        .ToList();
                    var groupAmount = await ConvertAllToDefaultCurrency(groupSuccessfulPayments, cancellationToken);

                    trends.Add(new PaymentTrendDto
                    {
                        Date = group.Key,
                        TransactionCount = totalCount,
                        TotalAmount = new MoneyDto
                        {
                            Amount = groupAmount,
                            Currency = DEFAULT_CURRENCY,
                            ExchangeRate = 1
                        },
                        SuccessRate = totalCount > 0 ? (double)successfulCount / totalCount * 100 : 0,
                        MethodBreakdown = groupPayments
                            .GroupBy(p => p.PaymentMethod.ToString())
                            .ToDictionary(g => g.Key, g => g.Count())
                    });
                }
            }
            else
            {
                // Group by week
                var weeklyGroups = payments
                    .GroupBy(p => GetWeekStart(p.PaymentDate))
                    .OrderBy(g => g.Key);

                foreach (var group in weeklyGroups)
                {
                    var groupPayments = group.ToList();
                    var successfulCount = groupPayments.Count(p => p.Status == PaymentStatus.Successful);
                    var totalCount = groupPayments.Count;

                    var weekGroupSuccessfulPayments = groupPayments
                        .Where(p => p.Status == PaymentStatus.Successful)
                        .Select(p => p.Amount)
                        .ToList();
                    var weekGroupAmount = await ConvertAllToDefaultCurrency(weekGroupSuccessfulPayments, default);
                    
                    trends.Add(new PaymentTrendDto
                    {
                        Date = group.Key,
                        TransactionCount = totalCount,
                        TotalAmount = new MoneyDto
                        {
                            Amount = weekGroupAmount,
                            Currency = DEFAULT_CURRENCY,
                            ExchangeRate = 1
                        },
                        SuccessRate = totalCount > 0 ? (double)successfulCount / totalCount * 100 : 0,
                        MethodBreakdown = groupPayments
                            .GroupBy(p => p.PaymentMethod.ToString())
                            .ToDictionary(g => g.Key, g => g.Count())
                    });
                }
            }

            return trends;
        }

        private async Task<Dictionary<string, MethodAnalyticsDto>> CalculateMethodAnalytics(
            List<Payment> payments,
            CancellationToken cancellationToken)
        {
            var successfulPayments = payments.Where(p => p.Status == PaymentStatus.Successful).ToList();
            var totalAmount = await ConvertAllToDefaultCurrency(
                successfulPayments.Select(p => p.Amount).ToList(),
                cancellationToken);
            var totalCount = payments.Count;

            var methodGroups = new Dictionary<string, MethodAnalyticsDto>();
            
            foreach (var group in payments.GroupBy(p => p.PaymentMethod.ToString()))
            {
                var methodPayments = group.ToList();
                var methodSuccessfulPayments = methodPayments.Where(p => p.Status == PaymentStatus.Successful).ToList();
                
                var methodAmount = await ConvertAllToDefaultCurrency(
                    methodSuccessfulPayments.Select(p => p.Amount).ToList(),
                    cancellationToken);
                
                var methodCount = methodPayments.Count;
                var successfulCount = methodSuccessfulPayments.Count;

                methodGroups[group.Key] = new MethodAnalyticsDto
                {
                    Method = group.Key,
                    TransactionCount = methodCount,
                    TotalAmount = new MoneyDto
                    {
                        Amount = methodAmount,
                        Currency = DEFAULT_CURRENCY,
                        ExchangeRate = 1
                    },
                    Percentage = totalCount > 0 ? Math.Round((double)methodCount / totalCount * 100, 2) : 0,
                    SuccessRate = methodCount > 0 ? Math.Round((double)successfulCount / methodCount * 100, 2) : 0,
                    AverageAmount = new MoneyDto
                    {
                        Amount = methodCount > 0 ? methodAmount / methodCount : 0,
                        Currency = DEFAULT_CURRENCY,
                        ExchangeRate = 1
                    }
                };
            }

            return methodGroups;
        }

        private async Task<Dictionary<string, StatusAnalyticsDto>> CalculateStatusAnalytics(
            List<Payment> payments,
            CancellationToken cancellationToken)
        {
            var totalCount = payments.Count;
            var statusGroups = new Dictionary<string, StatusAnalyticsDto>();

            foreach (var group in payments.GroupBy(p => p.Status.ToString()))
            {
                var statusPayments = group.ToList();
                var statusAmount = await ConvertAllToDefaultCurrency(
                    statusPayments.Select(p => p.Amount).ToList(),
                    cancellationToken);
                var statusCount = statusPayments.Count;

                statusGroups[group.Key] = new StatusAnalyticsDto
                {
                    Status = group.Key,
                    Count = statusCount,
                    TotalAmount = new MoneyDto
                    {
                        Amount = statusAmount,
                        Currency = DEFAULT_CURRENCY,
                        ExchangeRate = 1
                    },
                    Percentage = totalCount > 0 ? Math.Round((double)statusCount / totalCount * 100, 2) : 0
                };
            }

            return statusGroups;
        }

        private async Task<RefundAnalyticsDto> CalculateRefundAnalytics(
            List<Payment> payments,
            CancellationToken cancellationToken)
        {
            var refundedPayments = payments
                .Where(p => p.Status == PaymentStatus.Refunded || p.Status == PaymentStatus.PartiallyRefunded)
                .ToList();

            var totalRefunds = refundedPayments.Count;
            var totalRefundedAmount = await ConvertAllToDefaultCurrency(
                refundedPayments.Select(p => p.Amount).ToList(),
                cancellationToken);
            var totalTransactions = payments.Count;
            var refundRate = totalTransactions > 0 ? (double)totalRefunds / totalTransactions * 100 : 0;

            // Calculate average refund time (simplified - would need additional tracking in real scenario)
            var averageRefundTime = 0.0;

            // Group refunds by date for trends
            var refundTrends = new List<RefundTrendDto>();
            foreach (var group in refundedPayments
                .GroupBy(p => new DateTime(p.PaymentDate.Year, p.PaymentDate.Month, p.PaymentDate.Day))
                .OrderBy(g => g.Key))
            {
                var groupAmount = await ConvertAllToDefaultCurrency(
                    group.Select(p => p.Amount).ToList(),
                    cancellationToken);
                
                refundTrends.Add(new RefundTrendDto
                {
                    Date = group.Key,
                    RefundCount = group.Count(),
                    RefundedAmount = new MoneyDto
                    {
                        Amount = groupAmount,
                        Currency = DEFAULT_CURRENCY,
                        ExchangeRate = 1
                    }
                });
            }

            return new RefundAnalyticsDto
            {
                TotalRefunds = totalRefunds,
                TotalRefundedAmount = new MoneyDto
                {
                    Amount = totalRefundedAmount,
                    Currency = DEFAULT_CURRENCY,
                    ExchangeRate = 1
                },
                RefundRate = Math.Round(refundRate, 2),
                AverageRefundTime = averageRefundTime,
                RefundReasons = new Dictionary<string, int>(), // Would need additional tracking
                Trends = refundTrends
            };
        }

        /// <summary>
        /// تحويل جميع المبالغ إلى العملة الافتراضية (YER)
        /// Convert all amounts to default currency (YER)
        /// </summary>
        private async Task<decimal> ConvertAllToDefaultCurrency(
            List<YemenBooking.Core.ValueObjects.Money> amounts,
            CancellationToken cancellationToken)
        {
            if (amounts == null || !amounts.Any())
                return 0;

            decimal total = 0;

            foreach (var amount in amounts)
            {
                if (string.Equals(amount.Currency, DEFAULT_CURRENCY, StringComparison.OrdinalIgnoreCase))
                {
                    total += amount.Amount;
                    continue;
                }

                if (!_rateCache.TryGetValue(amount.Currency, out var rate))
                {
                    var exchangeRate = await _currencyExchangeRepository.GetExchangeRateAsync(
                        amount.Currency,
                        DEFAULT_CURRENCY);

                    if (exchangeRate != null && exchangeRate.IsActive)
                    {
                        rate = exchangeRate.Rate;
                        _rateCache[amount.Currency] = rate;
                    }
                    else
                    {
                        _logger.LogWarning(
                            "Exchange rate not found for {FromCurrency} to {ToCurrency}. Using 1.0 as rate.",
                            amount.Currency,
                            DEFAULT_CURRENCY);
                        rate = 1m;
                        _rateCache[amount.Currency] = rate;
                    }
                }

                total += amount.Amount * rate;
            }

            return total;
        }

        private DateTime GetWeekStart(DateTime date)
        {
            var diff = (7 + (date.DayOfWeek - DayOfWeek.Sunday)) % 7;
            return date.AddDays(-1 * diff).Date;
        }
    }
}
