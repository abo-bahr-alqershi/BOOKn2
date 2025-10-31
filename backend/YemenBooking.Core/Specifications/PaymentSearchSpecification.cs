using System;
using System.Linq.Expressions;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Specifications
{
    /// <summary>
    /// معاملات البحث في المدفوعات
    /// Payment search parameters
    /// </summary>
    public class PaymentSearchParameters
    {
        public string? PaymentMethod { get; set; }
        public string? Status { get; set; }
        public Guid? UserId { get; set; }
        public Guid? BookingId { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }

    /// <summary>
    /// مواصفة البحث في المدفوعات
    /// Specification for searching payments
    /// </summary>
    public class PaymentSearchSpecification : BaseSpecification<Payment>
    {
        public PaymentSearchSpecification(PaymentSearchParameters parameters)
            : base()
        {
            AddCriteria(p => true);

            if (!string.IsNullOrWhiteSpace(parameters.PaymentMethod))
            {
                var m = parameters.PaymentMethod.Trim().ToLower();
                AddCriteria(p => p.PaymentMethod.ToString().ToLower() == m);
            }

            if (!string.IsNullOrWhiteSpace(parameters.Status))
            {
                var s = parameters.Status.Trim().ToLower();
                AddCriteria(p => p.Status.ToString().ToLower() == s);
            }

            if (parameters.UserId.HasValue)
                AddCriteria(p => p.Booking.UserId == parameters.UserId.Value);

            if (parameters.BookingId.HasValue)
                AddCriteria(p => p.BookingId == parameters.BookingId.Value);

            if (parameters.StartDate.HasValue)
                AddCriteria(p => p.PaymentDate >= parameters.StartDate.Value);

            if (parameters.EndDate.HasValue)
                AddCriteria(p => p.PaymentDate <= parameters.EndDate.Value);

            if (parameters.PageNumber > 0 && parameters.PageSize > 0)
                ApplyPaging(parameters.PageNumber, parameters.PageSize);

            ApplyOrderBy(p => p.PaymentDate);
            ApplyNoTracking();
            ApplySplitQuery();
        }
    }
} 