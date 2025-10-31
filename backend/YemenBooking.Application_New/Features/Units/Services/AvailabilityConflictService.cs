using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Units.Services {
    /// <summary>
    /// خدمة إدارة تعارضات الإتاحة
    /// Availability Conflict Management Service
    /// </summary>
    public class AvailabilityConflictService : IAvailabilityConflictService
    {
        private readonly IUnitAvailabilityRepository _availabilityRepository;
        private readonly IBookingRepository _bookingRepository;
        private readonly ILogger<AvailabilityConflictService> _logger;

        public AvailabilityConflictService(
            IUnitAvailabilityRepository availabilityRepository,
            IBookingRepository bookingRepository,
            ILogger<AvailabilityConflictService> logger)
        {
            _availabilityRepository = availabilityRepository;
            _bookingRepository = bookingRepository;
            _logger = logger;
        }

        /// <summary>
        /// فحص التعارضات المحتملة
        /// Check for potential conflicts
        /// </summary>
        public async Task<AvailabilityConflictResult> CheckConflictsAsync(
            Guid unitId, 
            DateTime startDate, 
            DateTime endDate, 
            Guid? excludeBookingId = null)
        {
            var result = new AvailabilityConflictResult
            {
                HasConflicts = false,
                Conflicts = new List<ConflictDetail>()
            };

            try
            {
                // 1. Check availability records
                var availabilityRecords = await _availabilityRepository.GetByDateRangeAsync(unitId, startDate, endDate);
                
                foreach (var record in availabilityRecords.Where(r => !r.IsDeleted))
                {
                    // Skip if it's the booking we're excluding
                    if (excludeBookingId.HasValue && record.BookingId == excludeBookingId.Value)
                        continue;

                    // Check if this record blocks availability
                    if (!string.Equals(record.Status, AvailabilityStatus.Available, StringComparison.OrdinalIgnoreCase))
                    {
                        result.HasConflicts = true;
                        result.Conflicts.Add(new ConflictDetail
                        {
                            Type = ConflictType.AvailabilityBlock,
                            StartDate = record.StartDate,
                            EndDate = record.EndDate,
                            Status = record.Status,
                            Reason = record.Reason ?? GetDefaultReason(record.Status),
                            RelatedBookingId = record.BookingId
                        });
                    }
                }

                // 2. Check for overlapping bookings
                var bookings = await _bookingRepository.GetConflictingBookingsAsync(unitId, startDate, endDate);
                
                foreach (var booking in bookings)
                {
                    // Skip cancelled bookings
                    if (booking.Status == BookingStatus.Cancelled)
                        continue;

                    // Skip if it's the booking we're excluding
                    if (excludeBookingId.HasValue && booking.Id == excludeBookingId.Value)
                        continue;

                    result.HasConflicts = true;
                    result.Conflicts.Add(new ConflictDetail
                    {
                        Type = ConflictType.BookingConflict,
                        StartDate = booking.CheckIn,
                        EndDate = booking.CheckOut,
                        Status = booking.Status.ToString(),
                        Reason = $"حجز مؤكد رقم {booking.Id}",
                        RelatedBookingId = booking.Id
                    });
                }

                // Log the result
                if (result.HasConflicts)
                {
                    _logger.LogInformation("وجدت {Count} تعارضات للوحدة {UnitId} في الفترة من {Start} إلى {End}", 
                        result.Conflicts.Count, unitId, startDate, endDate);
                }
                else
                {
                    _logger.LogDebug("لا توجد تعارضات للوحدة {UnitId} في الفترة من {Start} إلى {End}", 
                        unitId, startDate, endDate);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء فحص التعارضات للوحدة {UnitId}", unitId);
                throw;
            }

            return result;
        }

        /// <summary>
        /// حل التعارضات تلقائياً إن أمكن
        /// Automatically resolve conflicts if possible
        /// </summary>
        public async Task<ConflictResolutionResult> ResolveConflictsAsync(
            Guid unitId,
            DateTime startDate,
            DateTime endDate,
            ConflictResolutionStrategy strategy,
            Guid? currentBookingId = null)
        {
            var result = new ConflictResolutionResult
            {
                Success = false,
                ResolvedConflicts = new List<ResolvedConflict>(),
                UnresolvedConflicts = new List<ConflictDetail>()
            };

            try
            {
                var conflicts = await CheckConflictsAsync(unitId, startDate, endDate, currentBookingId);
                
                if (!conflicts.HasConflicts)
                {
                    result.Success = true;
                    result.Message = "لا توجد تعارضات تحتاج إلى حل";
                    return result;
                }

                foreach (var conflict in conflicts.Conflicts)
                {
                    var resolved = false;

                    switch (strategy)
                    {
                        case ConflictResolutionStrategy.CancelConflicting:
                            // Cancel conflicting bookings (if authorized)
                            if (conflict.Type == ConflictType.BookingConflict && conflict.RelatedBookingId.HasValue)
                            {
                                // This would need authorization checks
                                _logger.LogWarning("محاولة إلغاء الحجز المتعارض {BookingId} - يتطلب صلاحيات", 
                                    conflict.RelatedBookingId.Value);
                            }
                            break;

                        case ConflictResolutionStrategy.SplitPeriod:
                            // Try to split the period to avoid conflict
                            if (CanSplitPeriod(conflict, startDate, endDate))
                            {
                                resolved = true;
                                result.ResolvedConflicts.Add(new ResolvedConflict
                                {
                                    OriginalConflict = conflict,
                                    ResolutionMethod = "تقسيم الفترة",
                                    NewStartDate = endDate > conflict.StartDate ? conflict.EndDate : startDate,
                                    NewEndDate = startDate < conflict.EndDate ? conflict.StartDate : endDate
                                });
                            }
                            break;

                        case ConflictResolutionStrategy.FindAlternative:
                            // This would need to find alternative units
                            _logger.LogInformation("البحث عن وحدة بديلة للفترة من {Start} إلى {End}", 
                                startDate, endDate);
                            break;

                        case ConflictResolutionStrategy.Override:
                            // Override conflicts (if authorized and for maintenance/owner use)
                            if (conflict.Status == AvailabilityStatus.Maintenance || 
                                conflict.Status == AvailabilityStatus.OwnerUse)
                            {
                                _logger.LogWarning("محاولة تجاوز {Status} - يتطلب صلاحيات", conflict.Status);
                            }
                            break;
                    }

                    if (!resolved)
                    {
                        result.UnresolvedConflicts.Add(conflict);
                    }
                }

                result.Success = result.UnresolvedConflicts.Count == 0;
                result.Message = result.Success 
                    ? "تم حل جميع التعارضات بنجاح" 
                    : $"تبقى {result.UnresolvedConflicts.Count} تعارضات لم يتم حلها";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء حل التعارضات للوحدة {UnitId}", unitId);
                result.Success = false;
                result.Message = "حدث خطأ أثناء حل التعارضات";
            }

            return result;
        }

        /// <summary>
        /// الحصول على الفترات المتاحة البديلة
        /// Get alternative available periods
        /// </summary>
        public async Task<List<AvailablePeriod>> GetAlternativePeriodsAsync(
            Guid unitId,
            DateTime preferredStart,
            DateTime preferredEnd,
            int maxDaysBefore = 30,
            int maxDaysAfter = 30)
        {
            var alternatives = new List<AvailablePeriod>();
            var duration = (preferredEnd - preferredStart).Days;
            
            // Search before preferred dates
            var searchStart = preferredStart.AddDays(-maxDaysBefore);
            var searchEnd = preferredEnd.AddDays(maxDaysAfter);
            
            // Get all availability records in the search range
            var records = await _availabilityRepository.GetByDateRangeAsync(unitId, searchStart, searchEnd);
            var bookings = await _bookingRepository.GetConflictingBookingsAsync(unitId, searchStart, searchEnd);
            
            // Build a timeline of availability
            var currentDate = searchStart;
            while (currentDate < searchEnd)
            {
                var testEnd = currentDate.AddDays(duration);
                if (testEnd > searchEnd) break;
                
                // Check if this period is available
                var hasConflict = records.Any(r => 
                    !r.IsDeleted && 
                    r.Status != AvailabilityStatus.Available &&
                    r.StartDate < testEnd && 
                    r.EndDate > currentDate);
                
                var hasBooking = bookings.Any(b => 
                    b.Status != BookingStatus.Cancelled &&
                    b.CheckIn < testEnd && 
                    b.CheckOut > currentDate);
                
                if (!hasConflict && !hasBooking)
                {
                    alternatives.Add(new AvailablePeriod
                    {
                        StartDate = currentDate,
                        EndDate = testEnd,
                        DaysFromPreferred = Math.Abs((currentDate - preferredStart).Days),
                        IsBeforePreferred = currentDate < preferredStart
                    });
                }
                
                currentDate = currentDate.AddDays(1);
            }
            
            // Sort by proximity to preferred dates
            return alternatives.OrderBy(a => a.DaysFromPreferred).ToList();
        }

        private bool CanSplitPeriod(ConflictDetail conflict, DateTime requestedStart, DateTime requestedEnd)
        {
            // Check if we can split the period to avoid the conflict
            return (conflict.StartDate > requestedStart && conflict.StartDate < requestedEnd) ||
                   (conflict.EndDate > requestedStart && conflict.EndDate < requestedEnd);
        }

        private string GetDefaultReason(string status)
        {
            return status switch
            {
                AvailabilityStatus.Booked => "محجوز من عميل",
                AvailabilityStatus.Blocked => "محظور",
                AvailabilityStatus.Maintenance => "تحت الصيانة",
                AvailabilityStatus.OwnerUse => "استخدام المالك",
                _ => "غير متاح"
            };
        }
    }

    // DTOs for the service
    public class AvailabilityConflictResult
    {
        public bool HasConflicts { get; set; }
        public List<ConflictDetail> Conflicts { get; set; } = new();
    }

    public class ConflictDetail
    {
        public ConflictType Type { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Status { get; set; } = string.Empty;
        public string Reason { get; set; } = string.Empty;
        public Guid? RelatedBookingId { get; set; }
    }

    public enum ConflictType
    {
        AvailabilityBlock,
        BookingConflict,
        MaintenancePeriod,
        OwnerUsePeriod
    }

    public class ConflictResolutionResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public List<ResolvedConflict> ResolvedConflicts { get; set; } = new();
        public List<ConflictDetail> UnresolvedConflicts { get; set; } = new();
    }

    public class ResolvedConflict
    {
        public ConflictDetail OriginalConflict { get; set; } = null!;
        public string ResolutionMethod { get; set; } = string.Empty;
        public DateTime? NewStartDate { get; set; }
        public DateTime? NewEndDate { get; set; }
    }

    public enum ConflictResolutionStrategy
    {
        None,
        CancelConflicting,
        SplitPeriod,
        FindAlternative,
        Override
    }

    public class AvailablePeriod
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int DaysFromPreferred { get; set; }
        public bool IsBeforePreferred { get; set; }
    }
}
