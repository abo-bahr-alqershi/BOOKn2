using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.Enums;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع المدفوعات
    /// Payment repository implementation
    /// </summary>
    public class PaymentRepository : BaseRepository<Payment>, IPaymentRepository
    {
        public PaymentRepository(YemenBookingDbContext context) : base(context) { }

        /// <summary>
        /// معالجة الدفع وإضافة سجل الدفع
        /// </summary>
        public async Task<Payment> ProcessPaymentAsync(Payment payment, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(payment, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return payment;
        }

        /// <summary>
        /// جلب سجل الدفع بناءً على المعرف
        /// </summary>
        public async Task<Payment?> GetPaymentByIdAsync(Guid paymentId, CancellationToken cancellationToken = default)
            => await _dbSet.FirstOrDefaultAsync(p => p.Id == paymentId, cancellationToken);

        /// <summary>
        /// تحديث بيانات الدفع وحفظها
        /// </summary>
        public async Task<Payment> UpdatePaymentAsync(Payment payment, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(payment);
            await _context.SaveChangesAsync(cancellationToken);
            return payment;
        }

        /// <summary>
        /// تحديث حالة الدفع (مثل معالج، ملغي)
        /// </summary>
        public async Task<bool> UpdatePaymentStatusAsync(Guid paymentId, string status, CancellationToken cancellationToken = default)
        {
            var payment = await GetPaymentByIdAsync(paymentId, cancellationToken);
            if (payment == null) return false;
            payment.Status = Enum.Parse<PaymentStatus>(status, true);
            _dbSet.Update(payment);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        /// <summary>
        /// حفظ سجل الدفع بدون معالجة إضافية
        /// </summary>
        public async Task<Payment> SavePaymentAsync(Payment payment, CancellationToken cancellationToken = default)
        {
            _dbSet.Add(payment);
            await _context.SaveChangesAsync(cancellationToken);
            return payment;
        }

        /// <summary>
        /// جلب جميع المدفوعات المتعلقة بحجز معين
        /// </summary>
        public async Task<IEnumerable<Payment>> GetPaymentsByBookingAsync(Guid bookingId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(p => p.BookingId == bookingId).ToListAsync(cancellationToken);

        /// <summary>
        /// جلب المدفوعات الخاصة بمستخدم في فترة زمنية محددة
        /// </summary>
        public async Task<IEnumerable<Payment>> GetPaymentsByUserAsync(Guid userId, DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default)
        {
            var query = _dbSet.Include(p => p.Booking).Where(p => p.Booking.UserId == userId);
            if (fromDate.HasValue) query = query.Where(p => p.PaymentDate >= fromDate.Value);
            if (toDate.HasValue) query = query.Where(p => p.PaymentDate <= toDate.Value);
            return await query.ToListAsync(cancellationToken);
        }

        /// <summary>
        /// جلب المدفوعات بناءً على الحالة (مثل "Paid", "Refunded")
        /// </summary>
        public async Task<IEnumerable<Payment>> GetPaymentsByStatusAsync(string status, CancellationToken cancellationToken = default)
        {
            var parsedStatus = Enum.Parse<PaymentStatus>(status, true);
            var query = _dbSet.Where(p => p.Status == parsedStatus);
            return await query.OrderByDescending(p => p.PaymentDate).ToListAsync(cancellationToken);
        }

        /// <summary>
        /// جلب المدفوعات وفقًا لطريقة الدفع وفترة زمنية
        /// </summary>
        public async Task<IEnumerable<Payment>> GetPaymentsByMethodAsync(string method, DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default)
        {
            // البحث عن طريقة الدفع بناءً على PaymentMethodEnum
            if (Enum.TryParse<YemenBooking.Core.Enums.PaymentMethodEnum>(method, true, out var paymentMethod))
            {
                var query = _dbSet.Where(p => p.PaymentMethod == paymentMethod);
                
                if (fromDate.HasValue) query = query.Where(p => p.PaymentDate >= fromDate.Value);
                if (toDate.HasValue) query = query.Where(p => p.PaymentDate <= toDate.Value);
                
                return await query.OrderByDescending(p => p.PaymentDate).ToListAsync(cancellationToken);
            }
            
            return new List<Payment>();
        }

        /// <summary>
        /// جلب بيانات الحجز المتعلقة بالدفع
        /// </summary>
        public async Task<Booking?> GetBookingByIdAsync(Guid bookingId, CancellationToken cancellationToken = default)
            => await _context.Set<Booking>().FirstOrDefaultAsync(b => b.Id == bookingId, cancellationToken);

        /// <summary>
        /// تنفيذ استرداد المبلغ وتحديث الحالة
        /// </summary>
        public async Task<bool> ProcessRefundAsync(Guid paymentId, decimal amount, string reason, CancellationToken cancellationToken = default)
        {
            var payment = await GetPaymentByIdAsync(paymentId, cancellationToken);
            if (payment == null) return false;
            payment.Status = PaymentStatus.Refunded;
            _dbSet.Update(payment);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        /// <summary>
        /// حساب توزيع الإيرادات حسب طريقة الدفع لفترة محددة
        /// </summary>
        public async Task<object> CalculateRevenueBreakdownAsync(DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
        {
            var breakdown = await _dbSet
                .Where(p => p.PaymentDate >= fromDate && p.PaymentDate <= toDate)
                .GroupBy(p => p.PaymentMethod)
                .Select(g => new { Method = g.Key, Total = g.Sum(p => p.Amount.Amount) })
                .ToListAsync(cancellationToken);
            return breakdown;
        }

        /// <summary>
        /// حساب هوامش الربح بعد التكاليف لفترة محددة
        /// </summary>
        public async Task<object> CalculateProfitMarginsAsync(DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
        {
            var margins = await _dbSet
                .Where(p => p.PaymentDate >= fromDate && p.PaymentDate <= toDate)
                .GroupBy(p => p.PaymentMethod)
                .Select(g => new { Method = g.Key, TotalMargin = g.Sum(p => p.Amount.Amount) })
                .ToListAsync(cancellationToken);
            return margins;
        }

        /// <summary>
        /// Get total paid amount for a booking
        /// </summary>
        public async Task<decimal> GetTotalPaidAmountAsync(Guid bookingId, CancellationToken cancellationToken = default)
        {
            var totals = await _dbSet
                .Where(p => p.BookingId == bookingId)
                .GroupBy(p => 1)
                .Select(g => new
                {
                    Paid = g.Where(p => p.Status == PaymentStatus.Successful || p.Status == PaymentStatus.PartiallyRefunded)
                              .Sum(p => (decimal?)p.Amount.Amount) ?? 0m,
                    Refunded = g.Where(p => p.Status == PaymentStatus.Refunded)
                                 .Sum(p => (decimal?)p.Amount.Amount) ?? 0m
                })
                .FirstOrDefaultAsync(cancellationToken);

            var netPaid = totals == null ? 0m : totals.Paid - totals.Refunded;
            return netPaid < 0 ? 0 : netPaid;
        }

        /// <summary>
        /// Get refunds for a payment
        /// </summary>
        public async Task<IEnumerable<Payment>> GetRefundsForPaymentAsync(Guid paymentId, CancellationToken cancellationToken = default)
        {
            var original = await GetPaymentByIdAsync(paymentId, cancellationToken);
            if (original == null)
                return Enumerable.Empty<Payment>();
            return await _dbSet
                .Where(p => p.Status == PaymentStatus.Refunded && p.BookingId == original.BookingId)
                .ToListAsync(cancellationToken);
        }
    }
} 