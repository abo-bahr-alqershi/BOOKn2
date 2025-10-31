using System;
using System.Linq;
using System.Linq.Expressions;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Specifications
{
    /// <summary>
    /// معاملات البحث عن الوحدات المتاحة
    /// Unit availability search parameters
    /// </summary>
    public class UnitAvailabilityParameters
    {
        public Guid PropertyId { get; set; }
        public DateTime CheckInDate { get; set; }
        public DateTime CheckOutDate { get; set; }
        public int NumberOfGuests { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public bool? IsAvailable { get; set; }
        public decimal? MinBasePrice { get; set; }
        public decimal? MaxBasePrice { get; set; }
        public int? MinCapacity { get; set; }
        public string? NameContains { get; set; }
    }

    /// <summary>
    /// مواصفة البحث عن الوحدات المتاحة
    /// Specification for searching available units
    /// </summary>
    public class UnitAvailabilitySpecification : BaseSpecification<Unit>
    {
        public UnitAvailabilitySpecification(UnitAvailabilityParameters parameters)
            : base()
        {
            // المعايير الأساسية: الوحدة في الكيان المحدد
            AddCriteria(u => u.PropertyId == parameters.PropertyId);

            // فلترة التوفر
            if (parameters.IsAvailable.HasValue)
            {
                AddCriteria(u => u.IsAvailable == parameters.IsAvailable.Value);
            }

            // نطاق السعر الأساسي
            if (parameters.MinBasePrice.HasValue)
                AddCriteria(u => u.BasePrice.Amount >= parameters.MinBasePrice.Value);
            if (parameters.MaxBasePrice.HasValue)
                AddCriteria(u => u.BasePrice.Amount <= parameters.MaxBasePrice.Value);

            // فلترة بالسعة
            if (parameters.MinCapacity.HasValue)
                AddCriteria(u => u.UnitType.MaxCapacity >= parameters.MinCapacity.Value);

            // بحث بالاسم
            if (!string.IsNullOrWhiteSpace(parameters.NameContains))
            {
                var term = parameters.NameContains.Trim().ToLower();
                AddCriteria(u => u.Name.ToLower().Contains(term));
            }

            // تضمينات
            AddInclude(u => u.UnitType);

            // التصفح
            if (parameters.PageNumber > 0 && parameters.PageSize > 0)
                ApplyPaging(parameters.PageNumber, parameters.PageSize);

            // تحسين الأداء
            ApplyNoTracking();
            ApplySplitQuery();
        }
    }
} 