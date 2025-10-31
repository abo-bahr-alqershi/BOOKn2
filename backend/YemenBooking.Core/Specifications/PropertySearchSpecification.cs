using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Specifications
{
    /// <summary>
    /// معاملات البحث في الكيانات
    /// Property search parameters
    /// </summary>
    public class PropertySearchParameters
    {
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public string? SearchTerm { get; set; }
        public Guid? PropertyTypeId { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string? SortBy { get; set; }
        public bool IsAscending { get; set; } = true;
        public IEnumerable<Guid>? AmenityIds { get; set; }
        public int[]? StarRatings { get; set; }
        public double? MinAverageRating { get; set; }
        public bool? IsApproved { get; set; }
        public bool? HasActiveBookings { get; set; }
    }

    /// <summary>
    /// مواصفة البحث في الكيانات
    /// Specification for searching properties
    /// </summary>
    public class PropertySearchSpecification : BaseSpecification<Property>
    {
        public PropertySearchSpecification(PropertySearchParameters parameters)
            : base()
        {
            // المعايير الأساسية: الكيانات غير المحذوفة
            AddCriteria(p => !p.IsDeleted);

            // البحث النصي
            if (!string.IsNullOrWhiteSpace(parameters.SearchTerm))
            {
                var term = parameters.SearchTerm.Trim().ToLower();
                AddCriteria(p => p.Name.ToLower().Contains(term) || p.Description.ToLower().Contains(term));
            }

            // فلترة حسب نوع الكيان
            if (parameters.PropertyTypeId.HasValue)
                AddCriteria(p => p.TypeId == parameters.PropertyTypeId.Value);

            // نطاق السعر
            if (parameters.MinPrice.HasValue)
                AddCriteria(p => p.Units.Any(u => u.BasePrice.Amount >= parameters.MinPrice.Value));
            if (parameters.MaxPrice.HasValue)
                AddCriteria(p => p.Units.Any(u => u.BasePrice.Amount <= parameters.MaxPrice.Value));

            // فلترة المرافق
            if (parameters.AmenityIds?.Any() == true)
            {
                foreach (var amenity in parameters.AmenityIds)
                    AddCriteria(p => p.Amenities.Any(a => a.PtaId == amenity));
            }

            // تقييم النجوم
            if (parameters.StarRatings?.Any() == true)
                AddCriteria(p => parameters.StarRatings.Contains(p.StarRating));

            // متوسط التقييم
            if (parameters.MinAverageRating.HasValue)
                AddCriteria(p => p.Reviews.Any() &&
                    p.Reviews.Average(r => (r.Cleanliness + r.Service + r.Location + r.Value) / 4.0) >= parameters.MinAverageRating.Value);

            // حالة الموافقة
            if (parameters.IsApproved.HasValue)
                AddCriteria(p => p.IsApproved == parameters.IsApproved.Value);

            // وجود حجوزات فعالة
            if (parameters.HasActiveBookings.HasValue)
            {
                if (parameters.HasActiveBookings.Value)
                    AddCriteria(p => p.Units.Any(u => u.Bookings.Any(b => b.Status != BookingStatus.Cancelled)));
                else
                    AddCriteria(p => !p.Units.Any(u => u.Bookings.Any(b => b.Status != BookingStatus.Cancelled)));
            }

            // تضمينات
            AddInclude(p => p.Owner);
            AddInclude(p => p.PropertyType);
            AddInclude(p => p.Units);
            AddInclude(p => p.Amenities);
            AddInclude(p => p.Images);

            // الترتيب
            if (!string.IsNullOrWhiteSpace(parameters.SortBy))
            {
                switch (parameters.SortBy.ToLower())
                {
                    case "name":
                        if (parameters.IsAscending) ApplyOrderBy(p => p.Name);
                        else ApplyOrderByDescending(p => p.Name);
                        break;
                    case "rating":
                        if (parameters.IsAscending) ApplyOrderBy(p => p.StarRating);
                        else ApplyOrderByDescending(p => p.StarRating);
                        break;
                    case "price":
                        if (parameters.IsAscending) ApplyOrderBy(p => p.Units.Min(u => u.BasePrice.Amount));
                        else ApplyOrderByDescending(p => p.Units.Min(u => u.BasePrice.Amount));
                        break;
                    case "created":
                    default:
                        if (parameters.IsAscending) ApplyOrderBy(p => p.CreatedAt);
                        else ApplyOrderByDescending(p => p.CreatedAt);
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