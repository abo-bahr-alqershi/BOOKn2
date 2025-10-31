using System;
using System.Linq;
using System.Linq.Expressions;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Specifications
{
    /// <summary>
    /// معاملات البحث في الحجوزات ضمن نطاق زمني
    /// Booking search parameters by date range
    /// </summary>
    public class BookingByDateRangeParameters
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public Guid? UserId { get; set; }
        public string? GuestNameOrEmail { get; set; }
        public Guid? UnitId { get; set; }
        public string? BookingSource { get; set; }
        public bool? IsWalkIn { get; set; }
        public decimal? MinTotalPrice { get; set; }
        public int? MinGuestsCount { get; set; }
        public string? SortBy { get; set; }
    }

    /// <summary>
    /// مواصفة البحث في الحجوزات ضمن نطاق زمني
    /// Specification for searching bookings by date range
    /// </summary>
    public class BookingByDateRangeSpecification : BaseSpecification<Booking>
    {
        public BookingByDateRangeSpecification(BookingByDateRangeParameters parameters)
            : base()
        {
            // المعايير الأساسية: الحجوزات ضمن الفترة المحددة
            AddCriteria(b => b.CheckIn >= parameters.StartDate && b.CheckOut <= parameters.EndDate);

            // فلترة بالمستخدم
            if (parameters.UserId.HasValue)
                AddCriteria(b => b.UserId == parameters.UserId.Value);

            // بحث باسم الضيف أو البريد الإلكتروني
            if (!string.IsNullOrWhiteSpace(parameters.GuestNameOrEmail))
            {
                var term = parameters.GuestNameOrEmail.Trim().ToLower();
                AddCriteria(b => b.User.Name.ToLower().Contains(term)
                                || b.User.Email.ToLower().Contains(term));
            }

            // فلترة بالوحدة
            if (parameters.UnitId.HasValue)
                AddCriteria(b => b.UnitId == parameters.UnitId.Value);

            // فلترة بمصدر الحجز
            if (!string.IsNullOrWhiteSpace(parameters.BookingSource))
            {
                var source = parameters.BookingSource.Trim().ToLower();
                AddCriteria(b => b.BookingSource != null && b.BookingSource.ToLower() == source);
            }

            // فلترة بالحجوزات المباشرة
            if (parameters.IsWalkIn.HasValue)
                AddCriteria(b => b.IsWalkIn == parameters.IsWalkIn.Value);

            // فلترة بالسعر الأدنى
            if (parameters.MinTotalPrice.HasValue)
                AddCriteria(b => b.TotalPrice.Amount >= parameters.MinTotalPrice.Value);

            // فلترة بعدد الضيوف
            if (parameters.MinGuestsCount.HasValue)
                AddCriteria(b => b.GuestsCount >= parameters.MinGuestsCount.Value);

            // تضمينات
            AddInclude(b => b.User);
            AddInclude(b => b.Unit);

            // الترتيب
            if (!string.IsNullOrWhiteSpace(parameters.SortBy))
            {
                switch (parameters.SortBy.ToLower())
                {
                    case "checkindate":
                        ApplyOrderBy(b => b.CheckIn);
                        break;
                    case "bookingdate":
                        ApplyOrderBy(b => b.BookedAt);
                        break;
                    case "totalprice":
                        ApplyOrderBy(b => b.TotalPrice.Amount);
                        break;
                    default:
                        ApplyOrderBy(b => b.CheckIn);
                        break;
                }
            }

            // التصفح
            if (parameters.PageNumber > 0 && parameters.PageSize > 0)
                ApplyPaging(parameters.PageNumber, parameters.PageSize);

            // تحسين الأداء
            ApplyNoTracking();
            ApplySplitQuery();
        }
    }
} 