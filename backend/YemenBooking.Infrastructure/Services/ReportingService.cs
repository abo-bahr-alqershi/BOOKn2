using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using System.Linq;
using System.IO;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة التقارير
    /// Reporting service implementation
    /// </summary>
    public class ReportingService : IReportingService
    {
        private readonly ILogger<ReportingService> _logger;
        private readonly IBookingRepository _bookingRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IUserRepository _userRepository;
        private readonly IExportService _exportService;

        public ReportingService(
            ILogger<ReportingService> logger,
            IBookingRepository bookingRepository,
            IPropertyRepository propertyRepository,
            IUserRepository userRepository,
            IExportService exportService)
        {
            _logger = logger;
            _bookingRepository = bookingRepository;
            _propertyRepository = propertyRepository;
            _userRepository = userRepository;
            _exportService = exportService;
        }

        public async Task<object> GetBookingReportAsync(DateTime fromDate, DateTime toDate, Guid? propertyId = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على تقرير الحجوزات من {FromDate} إلى {ToDate}", fromDate, toDate);
            var bookings = propertyId.HasValue
                ? await _bookingRepository.GetBookingsByPropertyAsync(propertyId.Value, fromDate, toDate, cancellationToken)
                : await _bookingRepository.GetBookingsByDateRangeAsync(fromDate, toDate, cancellationToken);
            var report = bookings
                .GroupBy(b => b.BookedAt.Date)
                .Select(g => new { Date = g.Key, Count = g.Count() })
                .OrderBy(r => r.Date)
                .ToList();
            return report;
        }

        public async Task<decimal> CalculateOccupancyRateAsync(Guid propertyId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("حساب معدل الإشغال للكيان: {PropertyId}", propertyId);
            var prop = await _propertyRepository.GetPropertyWithUnitsAsync(propertyId, cancellationToken);
            var unitsCount = prop?.Units.Count ?? 0;
            if (unitsCount == 0) return 0m;
            var bookings = await _bookingRepository.GetBookingsByPropertyAsync(propertyId, fromDate, toDate, cancellationToken);
            double bookedNights = bookings.Sum(b =>
            {
                var start = b.CheckIn < fromDate ? fromDate : b.CheckIn;
                var end = b.CheckOut > toDate ? toDate : b.CheckOut;
                return (end.Date - start.Date).TotalDays;
            });
            var totalNights = (toDate.Date - fromDate.Date).TotalDays * unitsCount;
            return totalNights > 0 ? (decimal)bookedNights / (decimal)totalNights : 0m;
        }

        public async Task<decimal> CalculateRevenueAsync(DateTime fromDate, DateTime toDate, Guid? propertyId = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("حساب الإيرادات من {FromDate} إلى {ToDate}", fromDate, toDate);
            return await _bookingRepository.GetTotalRevenueAsync(propertyId, fromDate, toDate, cancellationToken);
        }

        public async Task<object> GetRevenueReportAsync(DateTime fromDate, DateTime toDate, Guid? propertyId = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على تقرير الإيرادات من {FromDate} إلى {ToDate}", fromDate, toDate);
            var bookings = propertyId.HasValue
                ? await _bookingRepository.GetBookingsByPropertyAsync(propertyId.Value, fromDate, toDate, cancellationToken)
                : await _bookingRepository.GetBookingsByDateRangeAsync(fromDate, toDate, cancellationToken);
            var report = bookings
                .GroupBy(b => b.BookedAt.Date)
                .Select(g => new { Date = g.Key, Revenue = g.Sum(b => b.TotalPrice.Amount) })
                .OrderBy(r => r.Date)
                .ToList();
            return report;
        }

        public async Task<object> GetOccupancyReportAsync(DateTime fromDate, DateTime toDate, Guid propertyId, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على تقرير الإشغال للكيان: {PropertyId}", propertyId);
            var prop = await _propertyRepository.GetPropertyWithUnitsAsync(propertyId, cancellationToken);
            var unitsCount = prop?.Units.Count ?? 0;
            var dates = Enumerable.Range(0, (toDate.Date - fromDate.Date).Days + 1)
                .Select(i => fromDate.Date.AddDays(i));
            var bookings = await _bookingRepository.GetBookingsByPropertyAsync(propertyId, fromDate, toDate, cancellationToken);
            var report = dates.Select(date =>
            {
                var occupied = bookings.Count(b => b.CheckIn.Date <= date && b.CheckOut.Date > date);
                return new
                {
                    Date = date,
                    OccupiedUnits = occupied,
                    TotalUnits = unitsCount,
                    OccupancyRate = unitsCount > 0 ? (decimal)occupied / unitsCount : 0m
                };
            }).ToList();
            return report;
        }

        public async Task<object> GetCustomerReportAsync(DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على تقرير العملاء من {FromDate} إلى {ToDate}", fromDate, toDate);
            var bookings = await _bookingRepository.GetBookingsByDateRangeAsync(fromDate, toDate, cancellationToken);
            var report = bookings
                .GroupBy(b => b.UserId)
                .Select(g => new
                {
                    UserId = g.Key,
                    CustomerName = g.First().User.Name,
                    BookingsCount = g.Count(),
                    TotalSpent = g.Sum(b => b.TotalPrice.Amount)
                })
                .OrderByDescending(r => r.TotalSpent)
                .ToList();
            return report;
        }

        public Task<object> GetPropertyPerformanceAsync(Guid propertyId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على أداء الكيان: {PropertyId}", propertyId);
            return _propertyRepository.CalculatePerformanceMetricsAsync(propertyId, fromDate, toDate, cancellationToken);
        }

        public async Task<object> GetFinancialSummaryAsync(DateTime fromDate, DateTime toDate, Guid? propertyId = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على الملخص المالي من {FromDate} إلى {ToDate}", fromDate, toDate);
            var revenue = await CalculateRevenueAsync(fromDate, toDate, propertyId, cancellationToken);
            var bookingsCount = await _bookingRepository.GetTotalBookingsCountAsync(propertyId, fromDate, toDate, cancellationToken);
            var average = bookingsCount > 0 ? revenue / bookingsCount : 0m;
            return new { TotalRevenue = revenue, TotalBookings = bookingsCount, AverageBookingValue = average };
        }

        public async Task<byte[]> ExportReportAsync(string reportType, Dictionary<string, object> parameters, string format = "PDF", CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تصدير التقرير: {ReportType} بصيغة {Format}", reportType, format);
            var data = parameters.ContainsKey("data") ? parameters["data"] : new object();
            var result = await _exportService.ExportReportAsync(data, reportType, $"{reportType}.{format.ToLower()}", Enum.Parse<ExportFormat>(format, true), null, cancellationToken);
            if (!result.IsSuccess || string.IsNullOrEmpty(result.FilePath))
                return Array.Empty<byte>();
            return await File.ReadAllBytesAsync(result.FilePath, cancellationToken);
        }

        public Task<bool> ScheduleReportAsync(string reportType, Dictionary<string, object> parameters, string schedule, IEnumerable<string> recipients, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("جدولة التقرير: {ReportType} بالكرونية: {Schedule}", reportType, schedule);
            // TODO: دمج مع خدمة جدولة Cron مثل Quartz.NET
            return Task.FromResult(true);
        }
    }
} 