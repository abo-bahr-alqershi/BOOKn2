using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع خدمات الحجز
    /// Booking service repository implementation
    /// </summary>
    public class BookingServiceRepository : BaseRepository<BookingService>, IBookingServiceRepository
    {
        public BookingServiceRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<BookingService> AddServiceToBookingAsync(BookingService bookingService, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(bookingService, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return bookingService;
        }

        public async Task<bool> RemoveServiceFromBookingAsync(Guid bookingId, Guid serviceId, CancellationToken cancellationToken = default)
        {
            var bs = await _dbSet.FirstOrDefaultAsync(b => b.BookingId == bookingId && b.ServiceId == serviceId, cancellationToken);
            if (bs == null) return false;
            _dbSet.Remove(bs);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<IEnumerable<BookingService>> GetBookingServicesAsync(Guid bookingId, CancellationToken cancellationToken = default)
            => await _dbSet
                .Include(bs => bs.Service)
                .Where(bs => bs.BookingId == bookingId)
                .ToListAsync(cancellationToken);

        public async Task<BookingService> UpdateBookingServiceAsync(BookingService bookingService, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(bookingService);
            await _context.SaveChangesAsync(cancellationToken);
            return bookingService;
        }

        public async Task<BookingService?> GetBookingServiceByIdAsync(Guid bookingServiceId, CancellationToken cancellationToken = default)
            => await _dbSet.FindAsync(new object[]{bookingServiceId}, cancellationToken);
    }
} 