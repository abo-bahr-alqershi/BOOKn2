using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;
using System.Reflection;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.DTOs;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.AuditLog.Queries.GetAuditLogs
{
    /// <summary>
    /// معالج استعلام الحصول على سجلات التدقيق مع فلترة حسب المستخدم أو الفترة الزمنية
    /// Handler for GetAuditLogsQuery
    /// </summary>
    public class GetAuditLogsQueryHandler : IRequestHandler<GetAuditLogsQuery, PaginatedResult<YemenBooking.Application.Features.AuditLog.DTOs.AuditLogDto>>
    {
        private readonly YemenBooking.Application.Features.AuditLog.Services.IAuditService _auditService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetAuditLogsQueryHandler> _logger;
        private readonly IUserRepository _userRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IUnitRepository _unitRepository;
        private readonly IAmenityRepository _amenityRepository;
        private readonly IBookingRepository _bookingRepository;

        public GetAuditLogsQueryHandler(
            IAuditService auditService,
            ICurrentUserService currentUserService,
            IUserRepository userRepository,
            IPropertyRepository propertyRepository,
            IUnitRepository unitRepository,
            IAmenityRepository amenityRepository,
            IBookingRepository bookingRepository,
            ILogger<GetAuditLogsQueryHandler> logger)
        {
            _auditService = auditService;
            _currentUserService = currentUserService;
            _userRepository = userRepository;
            _propertyRepository = propertyRepository;
            _unitRepository = unitRepository;
            _amenityRepository = amenityRepository;
            _bookingRepository = bookingRepository;
            _logger = logger;
        }

        public async Task<PaginatedResult<YemenBooking.Application.Features.AuditLog.DTOs.AuditLogDto>> Handle(GetAuditLogsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("Processing GetAuditLogsQuery. UserId: {UserId}, From: {From}, To: {To}, SearchTerm: {SearchTerm}, OperationType: {OperationType}, PageNumber: {PageNumber}, PageSize: {PageSize}", request.UserId, request.From, request.To, request.SearchTerm, request.OperationType, request.PageNumber, request.PageSize);

            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
                throw new BusinessRuleException("Unauthorized", "يجب تسجيل الدخول لعرض سجلات التدقيق");

            if (!await _currentUserService.IsInRoleAsync("Admin"))
                throw new BusinessRuleException("Forbidden", "ليس لديك صلاحية لعرض سجلات التدقيق");

            // استعلام مرقم وخفيف على مستوى قاعدة البيانات
            AuditAction? parsedAction = null;
            if (!string.IsNullOrWhiteSpace(request.OperationType) && Enum.TryParse<AuditAction>(request.OperationType, true, out var actionEnum))
            {
                parsedAction = actionEnum;
            }

            // إذا طلب العميل السجلات المتعلقة بحجز معيّن، فادمج:
            // 1) سجلات الكيان Booking لهذا المعرف
            // 2) أي سجلات تحتوي الـ bookingId في الملاحظات (دفعات/توفر/غيرها)
            if (request.RelatedToBookingId.HasValue)
            {
                var bookingId = request.RelatedToBookingId.Value;

                // استرجاع سجلات الحجز مباشرة
                // Normalize incoming optional range to UTC for booking-related logs
                var fromUtcBooking = request.From.HasValue ? await _currentUserService.ConvertFromUserLocalToUtcAsync(request.From.Value) : (DateTime?)null;
                var toUtcBooking = request.To.HasValue ? await _currentUserService.ConvertFromUserLocalToUtcAsync(request.To.Value) : (DateTime?)null;

                var bookingLogs = await _auditService.GetAuditTrailAsync(
                    entityType: "Booking",
                    entityId: bookingId,
                    performedBy: request.UserId,
                    fromDate: fromUtcBooking,
                    toDate: toUtcBooking,
                    page: 1,
                    pageSize: Math.Max(request.PageSize, 50),
                    cancellationToken: cancellationToken);

                // استرجاع السجلات التي تذكر الـ bookingId في الملاحظات
                var (mentionedLogs, _) = await _auditService.SearchAuditLogsPagedAsync(
                    searchTerm: bookingId.ToString(),
                    action: parsedAction,
                    fromDate: fromUtcBooking,
                    toDate: toUtcBooking,
                    entityType: null,
                    entityId: null,
                    performedBy: request.UserId,
                    page: 1,
                    pageSize: Math.Max(request.PageSize * 2, 100),
                    cancellationToken: cancellationToken);

                // دمج وإزالة التكرار مع ترتيب زمني تنازلي
                var merged = bookingLogs
                    .Concat(mentionedLogs)
                    .GroupBy(a => a.Id)
                    .Select(g => g.First())
                    .OrderByDescending(a => a.Timestamp)
                    .ToList();

                var totalCountMerged = merged.Count;
                var skip = Math.Max(0, (request.PageNumber - 1) * request.PageSize);
                var bookingPageLogs = merged.Skip(skip).Take(request.PageSize).ToList();

                // التحويل إلى DTO وإرجاع
                var dtosMerged = new List<YemenBooking.Application.Features.AuditLog.DTOs.AuditLogDto>();
                foreach (var log in bookingPageLogs)
                {
                    var shortId = log.RecordId.ToString();
                    var shortUid = shortId.Length >= 8 ? shortId.Substring(0, 8) : shortId;
                    var recordName = string.Equals(log.TableName, "User", StringComparison.OrdinalIgnoreCase)
                        ? (string.IsNullOrWhiteSpace(log.Username) ? shortUid : log.Username!)
                        : shortUid;
                    var timestampLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(log.Timestamp);
                    dtosMerged.Add(new YemenBooking.Application.Features.AuditLog.DTOs.AuditLogDto
                    {
                        Id = log.Id,
                        TableName = log.TableName,
                        Action = log.Action,
                        RecordId = log.RecordId,
                        RecordName = recordName,
                        UserId = log.UserId,
                        Username = log.Username ?? string.Empty,
                        Notes = log.Notes ?? string.Empty,
                        OldValues = null,
                        NewValues = null,
                        Metadata = null,
                        IsSlowOperation = log.IsSlowOperation,
                        Changes = log.Notes ?? string.Empty,
                        Timestamp = timestampLocal
                    });
                }

                return new PaginatedResult<YemenBooking.Application.Features.AuditLog.DTOs.AuditLogDto>(dtosMerged, request.PageNumber, request.PageSize, totalCountMerged);
            }

            // خلاف ذلك: استخدم التصفية القياسية، لكن تجنّب تضييق النتائج بلا داعٍ عند وجود entityType+recordId
            var effectiveSearchTerm = (request.EntityType is null && request.RecordId is null)
                ? request.SearchTerm
                : null;

            // Normalize optional date filters from user's local time to UTC
            var fromUtc = request.From.HasValue ? await _currentUserService.ConvertFromUserLocalToUtcAsync(request.From.Value) : (DateTime?)null;
            var toUtc = request.To.HasValue ? await _currentUserService.ConvertFromUserLocalToUtcAsync(request.To.Value) : (DateTime?)null;

            var (pageLogs, totalCount) = await _auditService.SearchAuditLogsPagedAsync(
                searchTerm: effectiveSearchTerm,
                action: parsedAction,
                fromDate: fromUtc,
                toDate: toUtc,
                entityType: request.EntityType,
                entityId: request.RecordId,
                performedBy: request.UserId,
                page: request.PageNumber,
                pageSize: request.PageSize,
                cancellationToken: cancellationToken);

            // التحويل إلى DTO
            var dtos = new List<YemenBooking.Application.Features.AuditLog.DTOs.AuditLogDto>();
            foreach (var log in pageLogs)
            {
                var shortId = log.RecordId.ToString();
                var shortUid = shortId.Length >= 8 ? shortId.Substring(0, 8) : shortId;
                var recordName = string.Equals(log.TableName, "User", StringComparison.OrdinalIgnoreCase)
                    ? (string.IsNullOrWhiteSpace(log.Username) ? shortUid : log.Username!)
                    : shortUid;
                var timestampLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(log.Timestamp);

                dtos.Add(new YemenBooking.Application.Features.AuditLog.DTOs.AuditLogDto
                {
                    Id = log.Id,
                    TableName = log.TableName,
                    Action = log.Action,
                    RecordId = log.RecordId,
                    RecordName = recordName,
                    UserId = log.UserId,
                    Username = log.Username ?? string.Empty,
                    Notes = log.Notes ?? string.Empty,
                    // old/new/metadata are heavy; fetch in details endpoint when needed
                    OldValues = null,
                    NewValues = null,
                    Metadata = null,
                    IsSlowOperation = log.IsSlowOperation,
                    Changes = log.Notes ?? string.Empty,
                    Timestamp = timestampLocal
                });
            }
            return new PaginatedResult<YemenBooking.Application.Features.AuditLog.DTOs.AuditLogDto>(dtos, request.PageNumber, request.PageSize, totalCount);
        }

        /// <summary>
        /// Retrieves display name for given entity type and id.
        /// </summary>
        // Helper to load entity name
        private async Task<string> GetRecordNameAsync(string entityType, Guid recordId, CancellationToken cancellationToken)
        {
            switch (entityType)
            {
                case "User":
                    var user = await _userRepository.GetUserByIdAsync(recordId, cancellationToken);
                    return user?.Name ?? recordId.ToString();
                case "Property":
                    var property = await _propertyRepository.GetPropertyByIdAsync(recordId, cancellationToken);
                    return property?.Name ?? recordId.ToString();
                case "Unit":
                    var unit = await _unitRepository.GetUnitByIdAsync(recordId, cancellationToken);
                    return unit?.Name ?? recordId.ToString();
                case "Amenity":
                    var amenity = await _amenityRepository.GetAmenityByIdAsync(recordId, cancellationToken);
                    return amenity?.Name ?? recordId.ToString();
                case "Booking":
                    var booking = await _bookingRepository.GetBookingByIdAsync(recordId, cancellationToken);
                    return booking != null ? booking.Id.ToString().Substring(0, 8) : recordId.ToString();
                default:
                    return recordId.ToString();
            }
        }
    }
} 