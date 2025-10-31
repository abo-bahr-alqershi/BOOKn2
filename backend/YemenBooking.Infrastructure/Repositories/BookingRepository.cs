using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Core.Enums;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع الحجوزات
    /// Booking repository implementation
    /// </summary>
    public class BookingRepository : BaseRepository<Booking>, IBookingRepository
    {
        /// <summary>
        /// تهيئة مستودع الحجوزات
        /// </summary>
        public BookingRepository(YemenBookingDbContext context) : base(context) { }

        /// <summary>
        /// إنشاء حجز جديد
        /// </summary>
        public async Task<Booking> CreateBookingAsync(Booking booking, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(booking, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return booking;
        }

        /// <summary>
        /// الحصول على الحجز بناءً على المعرف
        /// </summary>
        public async Task<Booking?> GetBookingByIdAsync(Guid bookingId, CancellationToken cancellationToken = default)
            => await _dbSet.FirstOrDefaultAsync(b => b.Id == bookingId, cancellationToken);

        /// <summary>
        /// الحصول على الحجز مع الخدمات المرتبطة
        /// </summary>
        public async Task<Booking?> GetBookingWithServicesAsync(Guid bookingId, CancellationToken cancellationToken = default)
            => await _dbSet
                .Include(b => b.BookingServices)
                .ThenInclude(bs => bs.Service)
                .FirstOrDefaultAsync(b => b.Id == bookingId, cancellationToken);

        /// <summary>
        /// الحصول على الحجز مع المدفوعات المرتبطة
        /// </summary>
        public async Task<Booking?> GetBookingWithPaymentsAsync(Guid bookingId, CancellationToken cancellationToken = default)
            => await _dbSet
                .Include(b => b.Payments)
                .FirstOrDefaultAsync(b => b.Id == bookingId, cancellationToken);

        /// <summary>
        /// تعديل بيانات الحجز
        /// </summary>
        public async Task<Booking> UpdateBookingAsync(Booking booking, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(booking);
            await _context.SaveChangesAsync(cancellationToken);
            return booking;
        }

        /// <summary>
        /// تأكيد الحجز
        /// </summary>
        public async Task<bool> ConfirmBookingAsync(Guid bookingId, CancellationToken cancellationToken = default)
        {
            var booking = await GetBookingByIdAsync(bookingId, cancellationToken);
            if (booking == null) return false;
            booking.Status = BookingStatus.Confirmed;
            _dbSet.Update(booking);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        /// <summary>
        /// إلغاء الحجز مع سبب
        /// </summary>
        public async Task<bool> CancelBookingAsync(Guid bookingId, string reason, CancellationToken cancellationToken = default)
        {
            var booking = await GetBookingByIdAsync(bookingId, cancellationToken);
            if (booking == null) return false;
            booking.Status = BookingStatus.Cancelled;
            booking.CancellationReason = reason;
            _dbSet.Update(booking);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        /// <summary>
        /// إكمال الحجز
        /// </summary>
        public async Task<bool> CompleteBookingAsync(Guid bookingId, CancellationToken cancellationToken = default)
        {
            var booking = await GetBookingByIdAsync(bookingId, cancellationToken);
            if (booking == null) return false;
            booking.Status = BookingStatus.Completed;
            _dbSet.Update(booking);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        /// <summary>
        /// التحقق من الحجوزات النشطة لوحدة
        /// </summary>
        public async Task<bool> CheckActiveBookingsAsync(Guid unitId, CancellationToken cancellationToken = default)
            => await _dbSet.AnyAsync(b => b.UnitId == unitId && b.Status == BookingStatus.Confirmed, cancellationToken);

        /// <summary>
        /// الحصول على الحجوزات المتضاربة مع الفترة المحددة
        /// Get bookings that conflict with the given period for a unit
        /// </summary>
        public async Task<IEnumerable<Booking>> GetConflictingBookingsAsync(Guid unitId, DateTime checkIn, DateTime checkOut, CancellationToken cancellationToken = default)
            => await _dbSet
                .Where(b => b.UnitId == unitId &&
                            (b.Status == BookingStatus.Pending || b.Status == BookingStatus.Confirmed) &&
                            !(b.CheckOut <= checkIn || b.CheckIn >= checkOut))
                .ToListAsync(cancellationToken);

        /// <summary>
        /// جلب الحجوزات الخاصة بمستخدم
        /// </summary>
        public async Task<IEnumerable<Booking>> GetBookingsByUserAsync(Guid userId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(b => b.UserId == userId).ToListAsync(cancellationToken);

        /// <summary>
        /// جلب الحجوزات الخاصة بكيان في مدى زمني
        /// </summary>
        public async Task<IEnumerable<Booking>> GetBookingsByPropertyAsync(Guid propertyId, DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default)
        {
            var query = _dbSet
                .Include(b => b.Unit)
                .Where(b => b.Unit.PropertyId == propertyId);
            if (fromDate.HasValue) query = query.Where(b => b.CheckIn >= fromDate.Value);
            if (toDate.HasValue) query = query.Where(b => b.CheckOut <= toDate.Value);
            return await query.ToListAsync(cancellationToken);
        }

        /// <summary>
        /// جلب الحجوزات الخاصة بوحدة في مدى زمني
        /// </summary>
        public async Task<IEnumerable<Booking>> GetBookingsByUnitAsync(Guid unitId, DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default)
        {
            var query = _dbSet.Where(b => b.UnitId == unitId);
            if (fromDate.HasValue) query = query.Where(b => b.CheckIn >= fromDate.Value);
            if (toDate.HasValue) query = query.Where(b => b.CheckOut <= toDate.Value);
            return await query.ToListAsync(cancellationToken);
        }

        /// <summary>
        /// جلب الحجوزات حسب الحالة
        /// </summary>
        public async Task<IEnumerable<Booking>> GetBookingsByStatusAsync(BookingStatus status, CancellationToken cancellationToken = default)
            => await _dbSet.Where(b => b.Status == status).ToListAsync(cancellationToken);

        /// <summary>
        /// جلب الحجوزات في نطاق تاريخي
        /// </summary>
        public async Task<IEnumerable<Booking>> GetBookingsByDateRangeAsync(DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
            => await _dbSet.Where(b => b.CheckIn >= fromDate && b.CheckOut <= toDate).ToListAsync(cancellationToken);

        /// <summary>
        /// جلب الخدمات المرتبطة بحجز
        /// </summary>
        public async Task<IEnumerable<BookingService>> GetBookingServicesAsync(Guid bookingId, CancellationToken cancellationToken = default)
            => await _context.Set<BookingService>().Where(bs => bs.BookingId == bookingId).ToListAsync(cancellationToken);

        /// <summary>
        /// إضافة خدمة للحجز
        /// </summary>
        public async Task<bool> AddServiceToBookingAsync(Guid bookingId, Guid serviceId, int quantity = 1, CancellationToken cancellationToken = default)
        {
            var entity = new BookingService { BookingId = bookingId, ServiceId = serviceId, Quantity = quantity };
            await _context.Set<BookingService>().AddAsync(entity, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        /// <summary>
        /// إزالة خدمة من الحجز
        /// </summary>
        public async Task<bool> RemoveServiceFromBookingAsync(Guid bookingId, Guid serviceId, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Set<BookingService>().FirstOrDefaultAsync(bs => bs.BookingId == bookingId && bs.ServiceId == serviceId, cancellationToken);
            if (entity == null) return false;
            _context.Set<BookingService>().Remove(entity);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        /// <summary>
        /// إعادة حساب سعر الحجز (غير مستخدم)
        /// </summary>
        public async Task<decimal> RecalculatePriceAsync(Guid bookingId, CancellationToken cancellationToken = default)
        {
            var booking = await GetBookingByIdAsync(bookingId, cancellationToken);
            if (booking == null) return 0m;
            return booking.TotalPrice.Amount;
        }

        /// <summary>
        /// جلب إجمالي عدد الحجوزات في مدى تاريخي
        /// </summary>
        public async Task<int> GetTotalBookingsCountAsync(Guid? propertyId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
        {
            var query = GetPagedAsync(1, int.MaxValue, b => (!propertyId.HasValue || b.Unit.PropertyId == propertyId.Value) && b.BookedAt >= fromDate && b.BookedAt <= toDate, null, true, cancellationToken);
            return (await query).TotalCount;
        }

        /// <summary>
        /// جلب إجمالي الإيرادات في مدى تاريخي
        /// </summary>
        public async Task<decimal> GetTotalRevenueAsync(Guid? propertyId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
        {
            var bookings = await GetBookingsByDateRangeAsync(fromDate, toDate, cancellationToken);
            return bookings.Where(b => !propertyId.HasValue || b.Unit.PropertyId == propertyId.Value).Sum(b => b.TotalPrice.Amount);
        }

        /// <summary>
        /// جلب مواعيد الوصول القادمة لكيان
        /// </summary>
        public async Task<IEnumerable<Booking>> GetUpcomingCheckInsAsync(Guid propertyId, int days, CancellationToken cancellationToken = default)
        {
            var today = DateTime.UtcNow.Date;
            var target = today.AddDays(days);
            return await _dbSet.Where(b => b.Unit.PropertyId == propertyId && b.CheckIn >= today && b.CheckIn <= target).ToListAsync(cancellationToken);
        }

        /// <summary>
        /// جلب أول تاريخ حجز لكل مستخدم
        /// </summary>
        public async Task<Dictionary<Guid, DateTime>> GetFirstBookingDateForUsersAsync(IEnumerable<Guid> userIds, CancellationToken cancellationToken = default)
        {
            return await _dbSet
                .Where(b => userIds.Contains(b.UserId))
                .GroupBy(b => b.UserId)
                .Select(g => new { UserId = g.Key, Date = g.Min(b => b.BookedAt) })
                .ToDictionaryAsync(x => x.UserId, x => x.Date, cancellationToken);
        }

        /// <summary>
        /// جلب إجمالي العمولة في مدى تاريخي
        /// </summary>
        public async Task<decimal> GetTotalCommissionAsync(DateTime startDate, DateTime endDate, CancellationToken cancellationToken = default)
        {
            return await _dbSet
                .Where(b => b.BookedAt >= startDate && b.BookedAt <= endDate)
                .SumAsync(b => b.PlatformCommissionAmount, cancellationToken);
        }

        /// <summary>
        /// جلب ملخص أسباب الإلغاء في مدى تاريخي
        /// </summary>
        public async Task<IEnumerable<CancellationReasonSummary>> GetCancellationReasonsSummaryAsync(DateTime startDate, DateTime endDate, CancellationToken cancellationToken = default)
            => await _dbSet
                .Where(b => b.CancellationReason != null && b.BookedAt >= startDate && b.BookedAt <= endDate)
                .GroupBy(b => b.CancellationReason)
                .Select(g => new CancellationReasonSummary { Reason = g.Key!, Count = g.Count() })
                .ToListAsync(cancellationToken);
    }
} 