using System;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Analytics.DTOs;

namespace YemenBooking.Application.Features.Analytics.Commands.Reports
{
    /// <summary>
    /// معالج أمر تصدير تقرير لوحة التحكم بالتنسيق المحدد
    /// </summary>
    public class ExportDashboardReportCommandHandler : IRequestHandler<ExportDashboardReportCommand, byte[]>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IBookingRepository _bookingRepository;
        private readonly IUserRepository _userRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IExportService _exportService;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<ExportDashboardReportCommandHandler> _logger;

        public ExportDashboardReportCommandHandler(
            IUnitOfWork unitOfWork,
            IBookingRepository bookingRepository,
            IUserRepository userRepository,
            IPropertyRepository propertyRepository,
            IExportService exportService,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<ExportDashboardReportCommandHandler> logger)
        {
            _unitOfWork = unitOfWork;
            _bookingRepository = bookingRepository;
            _userRepository = userRepository;
            _propertyRepository = propertyRepository;
            _exportService = exportService;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        /// <inheritdoc />
        public async Task<byte[]> Handle(ExportDashboardReportCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تصدير تقرير لوحة التحكم: Type={Type}, TargetId={TargetId}, Format={Format}",
                request.DashboardType, request.TargetId, request.Format);

            // التحقق من صحة المدخلات
            if (request.TargetId == Guid.Empty)
                throw new ArgumentException("معرف الهدف مطلوب");

            // التحقق من الصلاحيات
            if (request.DashboardType == DashboardType.Admin && _currentUserService.Role != "Admin")
                throw new UnauthorizedAccessException("غير مصرح لك بتصدير تقارير المسؤول");
            if (request.DashboardType == DashboardType.Owner && !(_currentUserService.Role == "Admin" || request.TargetId == _currentUserService.UserId))
                throw new UnauthorizedAccessException("غير مصرح لك بتصدير تقارير المالك");
            if (request.DashboardType == DashboardType.Customer && !(_currentUserService.Role == "Admin" || request.TargetId == _currentUserService.UserId))
                throw new UnauthorizedAccessException("غير مصرح لك بتصدير تقارير العميل");

            // الحصول على البيانات المناسبة
            object reportData;
            string fileName = $"{request.DashboardType}_Report_{DateTime.UtcNow:yyyyMMddHHmmss}.json";
            switch (request.DashboardType)
            {
                case DashboardType.Admin:
                    var totalUsers = await _unitOfWork.Repository<YemenBooking.Core.Entities.User>().CountAsync(cancellationToken);
                    var totalProperties = await _unitOfWork.Repository<YemenBooking.Core.Entities.Property>().CountAsync(cancellationToken);
                    var totalBookings = await _bookingRepository.CountAsync(cancellationToken);
                    var totalRevenue = await _bookingRepository.GetTotalRevenueAsync(null, DateTime.MinValue, DateTime.UtcNow, cancellationToken);
                    reportData = new AdminDashboardDto
                    {
                        TotalUsers = totalUsers,
                        TotalProperties = totalProperties,
                        TotalBookings = totalBookings,
                        TotalRevenue = totalRevenue
                    };
                    break;
                case DashboardType.Owner:
                    var owner = await _userRepository.GetUserByIdAsync(request.TargetId, cancellationToken);
                    if (owner == null)
                        throw new KeyNotFoundException("المالك غير موجود");
                    var props = await _propertyRepository.GetPropertiesByOwnerAsync(request.TargetId, cancellationToken);
                    int propCount = props.Count();
                    int bookingCount = 0;
                    decimal revenue = 0m;
                    foreach (var p in props)
                    {
                        var bookingsByProp = await _bookingRepository.GetBookingsByPropertyAsync(p.Id, null, null, cancellationToken);
                        bookingCount += bookingsByProp.Count();
                        revenue += await _bookingRepository.GetTotalRevenueAsync(p.Id, DateTime.MinValue, DateTime.UtcNow, cancellationToken);
                    }
                    reportData = new OwnerDashboardDto
                    {
                        OwnerId = owner.Id,
                        OwnerName = owner.Name,
                        PropertyCount = propCount,
                        BookingCount = bookingCount,
                        TotalRevenue = revenue
                    };
                    break;
                case DashboardType.Customer:
                    var customer = await _userRepository.GetUserByIdAsync(request.TargetId, cancellationToken);
                    if (customer == null)
                        throw new KeyNotFoundException("المستخدم غير موجود");
                    var custBookings = await _bookingRepository.GetBookingsByUserAsync(request.TargetId, cancellationToken);
                    // Compute user's local 'today' boundary once, then convert to UTC for comparisons
                    var userNowLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow);
                    var userTodayLocal = userNowLocal.Date;
                    var startOfTodayLocal = userTodayLocal; // 00:00 local
                    var startOfTodayUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(startOfTodayLocal);
                    int upcoming = custBookings.Count(b => b.CheckIn >= startOfTodayUtc);
                    int past = custBookings.Count(b => b.CheckOut < startOfTodayUtc);
                    decimal spent = custBookings.Sum(b => b.TotalPrice.Amount);
                    reportData = new CustomerDashboardDto
                    {
                        CustomerId = customer.Id,
                        CustomerName = customer.Name,
                        UpcomingBookings = upcoming,
                        PastBookings = past,
                        TotalSpent = spent
                    };
                    break;
                default:
                    throw new ArgumentOutOfRangeException(nameof(request.DashboardType), "نوع لوحة التحكم غير مدعوم");
            }

            // تصدير التقرير
            var exportFormat = (ExportFormat)Enum.Parse(typeof(ExportFormat), request.Format.ToString(), true);
            var exportResult = await _exportService.ExportReportAsync(
                reportData,
                request.DashboardType.ToString(),
                fileName,
                exportFormat,
                null,
                cancellationToken);
            if (!exportResult.IsSuccess)
                throw new InvalidOperationException($"خطأ أثناء تصدير التقرير: {exportResult.ErrorMessage}");

            // تسجيل عملية التصدير في السجل (يدوي) مع ذكر اسم المستخدم والمعرف
            var notes = $"تم تصدير تقرير لوحة التحكم '{request.DashboardType}' بصيغة {request.Format} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "Dashboard",
                entityId: request.TargetId,
                action: AuditAction.EXPORT,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { Exported = true, request.DashboardType, request.Format }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            // قراءة الملف وإرجاع المحتوى
            var fileBytes = await File.ReadAllBytesAsync(exportResult.FilePath, cancellationToken);
            return fileBytes;
        }
    }
} 