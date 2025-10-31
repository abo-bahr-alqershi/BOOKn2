// using System;
// using System.Collections.Generic;
// using System.Threading;
// using System.Threading.Tasks;
// using Microsoft.Extensions.Logging;
// using YemenBooking.Application.Infrastructure.Services;
// using System.Linq;
// using Microsoft.EntityFrameworkCore;
// using YemenBooking.Infrastructure.Data.Context;
// using YemenBooking.Core.Entities;

// namespace YemenBooking.Infrastructure.Services
// {
//     /// <summary>
//     /// تنفيذ خدمة التوفر
//     /// Availability service implementation
//     /// </summary>
//     public class AvailabilityService : IAvailabilityService
//     {
//         private readonly ILogger<AvailabilityService> _logger;
//         private readonly YemenBookingDbContext _dbContext;

//         public AvailabilityService(ILogger<AvailabilityService> logger, YemenBookingDbContext dbContext)
//         {
//             _logger = logger;
//             _dbContext = dbContext;
//         }

//         /// <inheritdoc />
//         public async Task<bool> CheckAvailabilityAsync(Guid unitId, DateTime checkIn, DateTime checkOut, CancellationToken cancellationToken = default)
//         {
//             // تحقق من التعارض مع الحجوزات
//             var bookingOverlap = await _dbContext.Bookings
//                 .AnyAsync(b => b.UnitId == unitId && b.CheckIn < checkOut && b.CheckOut > checkIn, cancellationToken);
//             if (bookingOverlap)
//                 return false;
            
//             // تحقق من التعارض مع التجاوزات اليدوية (الإتاحة الموقوفة)
//             var overrideOverlap = await _dbContext.Set<UnitAvailability>()
//                 .AnyAsync(u => u.UnitId == unitId
//                     && u.StartDate < checkOut
//                     && u.EndDate > checkIn
//                     && !u.Status.Equals("available", StringComparison.OrdinalIgnoreCase), cancellationToken);
//             if (overrideOverlap)
//                 return false;
            
//             return true;
//         }

//         /// <inheritdoc />
//         public async Task<IDictionary<Guid, bool>> CheckMultipleUnitsAvailabilityAsync(IEnumerable<Guid> unitIds, DateTime checkIn, DateTime checkOut, CancellationToken cancellationToken = default)
//         {
//             var result = new Dictionary<Guid, bool>();
//             foreach (var unitId in unitIds)
//             {
//                 var avail = await CheckAvailabilityAsync(unitId, checkIn, checkOut, cancellationToken);
//                 result[unitId] = avail;
//             }
//             return result;
//         }

//         /// <inheritdoc />
//         public async Task<IEnumerable<Guid>> GetAvailableUnitsInPropertyAsync(Guid propertyId, DateTime checkIn, DateTime checkOut, int guestCount, CancellationToken cancellationToken = default)
//         {
//             var units = await _dbContext.Units.Where(u => u.PropertyId == propertyId).Select(u => u.Id).ToListAsync(cancellationToken);
//             var available = new List<Guid>();
//             foreach (var unitId in units)
//             {
//                 if (await CheckAvailabilityAsync(unitId, checkIn, checkOut, cancellationToken))
//                     available.Add(unitId);
//             }
//             return available;
//         }

//         /// <inheritdoc />
//         public async Task<IEnumerable<(DateTime Start, DateTime End, bool IsAvailable)>> GetUnitAvailabilityPeriodsAsync(Guid unitId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
//         {
//             var bookings = await _dbContext.Bookings
//                 .Where(b => b.UnitId == unitId && b.CheckOut >= fromDate && b.CheckIn <= toDate)
//                 .OrderBy(b => b.CheckIn)
//                 .ToListAsync(cancellationToken);
//             var periods = new List<(DateTime, DateTime, bool)>();
//             var current = fromDate;
//             foreach (var b in bookings)
//             {
//                 if (b.CheckIn > current)
//                     periods.Add((current, b.CheckIn, true));
//                 periods.Add((b.CheckIn, b.CheckOut, false));
//                 current = b.CheckOut;
//             }
//             if (current < toDate)
//                 periods.Add((current, toDate, true));
//             return periods;
//         }

//         /// <inheritdoc />
//         public Task<bool> BlockUnitPeriodAsync(Guid unitId, DateTime fromDate, DateTime toDate, string reason, CancellationToken cancellationToken = default)
//         {
//             return Task.FromResult(true);
//         }

//         /// <inheritdoc />
//         public Task<bool> UnblockUnitPeriodAsync(Guid unitId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
//         {
//             return Task.FromResult(true);
//         }

//         /// <inheritdoc />
//         public async Task<double> CalculateOccupancyRateAsync(Guid unitId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
//         {
//             var totalDays = (toDate - fromDate).TotalDays;
//             if (totalDays <= 0) return 0;
//             var bookings = await _dbContext.Bookings
//                 .Where(b => b.UnitId == unitId && b.CheckOut >= fromDate && b.CheckIn <= toDate)
//                 .ToListAsync(cancellationToken);
//             var busyDays = bookings.Sum(b =>
//             {
//                 var start = b.CheckIn < fromDate ? fromDate : b.CheckIn;
//                 var end = b.CheckOut > toDate ? toDate : b.CheckOut;
//                 return (end - start).TotalDays;
//             });
//             return Math.Round(busyDays / totalDays * 100, 2);
//         }

//         /// <inheritdoc />
//         public async Task<double> CalculatePropertyOccupancyRateAsync(Guid propertyId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
//         {
//             var unitIds = await _dbContext.Units.Where(u => u.PropertyId == propertyId).Select(u => u.Id).ToListAsync(cancellationToken);
//             if (!unitIds.Any()) return 0;
//             var rates = new List<double>();
//             foreach (var unitId in unitIds)
//                 rates.Add(await CalculateOccupancyRateAsync(unitId, fromDate, toDate, cancellationToken));
//             return Math.Round(rates.Average(), 2);
//         }
//     }
// }

using System.Linq;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features.Units.Commands.BulkOperations;
using YemenBooking.Core.Interfaces.Repositories;
using Microsoft.Extensions.Logging;

namespace YemenBooking.Infrastructure.Services;

public class AvailabilityService : IAvailabilityService
{
    private readonly IUnitAvailabilityRepository _availabilityRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly ILogger<AvailabilityService> _logger;

    // Constructor with logger (preferred)
    public AvailabilityService(
        IUnitAvailabilityRepository availabilityRepository,
        IUnitRepository unitRepository,
        ILogger<AvailabilityService> logger)
    {
        _availabilityRepository = availabilityRepository;
        _unitRepository = unitRepository;
        _logger = logger;
    }

    // Constructor without logger (for backward compatibility)
    public AvailabilityService(
        IUnitAvailabilityRepository availabilityRepository,
        IUnitRepository unitRepository)
    {
        _availabilityRepository = availabilityRepository;
        _unitRepository = unitRepository;
        _logger = null!; // Will be null, so we need to check before logging
    }

    public async Task<bool> CheckAvailabilityAsync(Guid unitId, DateTime checkIn, DateTime checkOut, Guid? excludeBookingId = null)
    {
        _logger?.LogDebug("التحقق من توفر الوحدة {UnitId} من {CheckIn} إلى {CheckOut}، استثناء الحجز: {ExcludeBookingId}", 
            unitId, checkIn, checkOut, excludeBookingId);
        
        // Check if unit exists and is active
        var unit = await _unitRepository.GetByIdAsync(unitId);
        if (unit == null)
        {
            _logger?.LogWarning("الوحدة {UnitId} غير موجودة", unitId);
            return false;
        }
        
        if (!unit.IsAvailable)
        {
            _logger?.LogWarning("الوحدة {UnitId} غير متاحة (IsAvailable = false)", unitId);
            return false;
        }

        // Check for any blocks in the period (excluding the specified booking if provided)
        var isAvailable = await _availabilityRepository.IsUnitAvailableAsync(unitId, checkIn, checkOut, excludeBookingId);
        
        _logger?.LogInformation("نتيجة التحقق من توفر الوحدة {UnitId}: {IsAvailable}", unitId, isAvailable);
        
        return isAvailable;
    }

    public async Task BlockForBookingAsync(Guid unitId, Guid bookingId, DateTime checkIn, DateTime checkOut)
    {
        var availability = new UnitAvailability
        {
            Id = Guid.NewGuid(),
            UnitId = unitId,
            BookingId = bookingId,
            StartDate = checkIn,
            EndDate = checkOut,
            Status = AvailabilityStatus.Booked,
            Reason = "Customer Booking",
            CreatedAt = DateTime.UtcNow
        };

        await _availabilityRepository.AddAsync(availability);
        await _availabilityRepository.SaveChangesAsync();
    }

    public async Task ReleaseBookingAsync(Guid bookingId)
    {
        var all = await _availabilityRepository.GetAllAsync();
        var blocks = all.Where(ua => ua.BookingId == bookingId);

        foreach (var block in blocks)
        {
            block.IsDeleted = true;
            block.DeletedAt = DateTime.UtcNow;
            await _availabilityRepository.UpdateAsync(block);
        }
        await _availabilityRepository.SaveChangesAsync();
    }

    public async Task<Dictionary<DateTime, string>> GetMonthlyCalendarAsync(Guid unitId, int year, int month)
    {
        return await _availabilityRepository.GetAvailabilityCalendarAsync(unitId, year, month);
    }

    public async Task ApplyBulkAvailabilityAsync(Guid unitId, List<AvailabilityPeriodDto> periods)
    {
        var availabilities = new List<UnitAvailability>();

        foreach (var period in periods)
        {
            // Delete existing availability in this range if needed
            if (period.OverwriteExisting)
            {
                await _availabilityRepository.DeleteRangeAsync(unitId, period.StartDate, period.EndDate);
            }

            var availability = new UnitAvailability
            {
                Id = Guid.NewGuid(),
                UnitId = unitId,
                StartDate = period.StartDate,
                EndDate = period.EndDate,
                Status = period.Status,
                Reason = period.Reason,
                Notes = period.Notes,
                CreatedAt = DateTime.UtcNow
            };

            availabilities.Add(availability);
        }

        // حفظ الدفعة مرة واحدة
        await _availabilityRepository.BulkCreateAsync(availabilities);
    }
    
    public async Task<IEnumerable<Guid>> GetAvailableUnitsInPropertyAsync(Guid propertyId, DateTime checkIn, DateTime checkOut, int guestCount, CancellationToken cancellationToken = default)
    {
        var units = await _unitRepository.GetUnitsByPropertyAsync(propertyId, cancellationToken);
        var available = new List<Guid>();
        foreach (var unit in units)
        {
            if (await CheckAvailabilityAsync(unit.Id, checkIn, checkOut))
                available.Add(unit.Id);
        }
        return available;
    }
}