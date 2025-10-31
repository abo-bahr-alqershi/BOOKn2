using System;
using System.Linq;
using System.Linq.Expressions;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Specifications
{
    /// <summary>
    /// معاملات البحث في المراجعات
    /// Review search parameters
    /// </summary>
    public class ReviewSearchParameters
    {
        public Guid? UserId { get; set; }
        public Guid? PropertyId { get; set; }
        public int? MinRating { get; set; }
        public int? MaxRating { get; set; }
        public bool? IsPendingApproval { get; set; }
        public bool? HasResponse { get; set; }
        public DateTime? ReviewedAfter { get; set; }
        public string? SortBy { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }

    /// <summary>
    /// مواصفة البحث في المراجعات
    /// Specification for searching reviews
    /// </summary>
    public class ReviewSearchSpecification : BaseSpecification<Review>
    {
        public ReviewSearchSpecification(ReviewSearchParameters parameters)
            : base()
        {
            AddCriteria(r => true);

            if (parameters.UserId.HasValue)
                AddCriteria(r => r.Booking.UserId == parameters.UserId.Value);

            if (parameters.PropertyId.HasValue)
                AddCriteria(r => r.Property.Id == parameters.PropertyId.Value);

            if (parameters.MinRating.HasValue)
                AddCriteria(r => (r.Cleanliness + r.Service + r.Location + r.Value) / 4.0 >= parameters.MinRating.Value);

            if (parameters.MaxRating.HasValue)
                AddCriteria(r => (r.Cleanliness + r.Service + r.Location + r.Value) / 4.0 <= parameters.MaxRating.Value);

            if (parameters.IsPendingApproval.HasValue)
                AddCriteria(r => r.IsPendingApproval == parameters.IsPendingApproval.Value);

            if (parameters.HasResponse.HasValue)
                AddCriteria(r => (parameters.HasResponse.Value ? r.ResponseText != null : r.ResponseText == null));

            if (parameters.ReviewedAfter.HasValue)
                AddCriteria(r => r.CreatedAt >= parameters.ReviewedAfter.Value);

            if (!string.IsNullOrWhiteSpace(parameters.SortBy))
            {
                // ترتيب حسب معايير محددة
                var sort = parameters.SortBy.Trim().ToLower();
                switch (sort)
                {
                    case "cleanliness": ApplyOrderBy(r => r.Cleanliness); break;
                    case "service": ApplyOrderBy(r => r.Service); break;
                    case "location": ApplyOrderBy(r => r.Location); break;
                    case "value": ApplyOrderBy(r => r.Value); break;
                    case "date": ApplyOrderBy(r => r.CreatedAt); break;
                    default: ApplyOrderBy(r => r.CreatedAt); break;
                }
            }

            if (parameters.PageNumber > 0 && parameters.PageSize > 0)
                ApplyPaging(parameters.PageNumber, parameters.PageSize);

            ApplyNoTracking();
            ApplySplitQuery();
        }
    }
} 