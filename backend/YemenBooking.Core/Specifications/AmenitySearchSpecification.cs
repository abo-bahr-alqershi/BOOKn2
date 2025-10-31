using System;
using System.Linq;
using System.Linq.Expressions;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Specifications
{
    /// <summary>
    /// معاملات البحث في المرافق
    /// Amenity search parameters
    /// </summary>
    public class AmenitySearchParameters
    {
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public string? SearchTerm { get; set; }
        public Guid? PropertyTypeId { get; set; }
    }

    /// <summary>
    /// مواصفة البحث في المرافق
    /// Specification for searching amenities
    /// </summary>
    public class AmenitySearchSpecification : BaseSpecification<Amenity>
    {
        public AmenitySearchSpecification(AmenitySearchParameters parameters)
            : base()
        {
            // فلترة المرافق غير المحذوفة
            AddCriteria(a => !a.IsDeleted);

            // البحث النصي بالاسم أو الوصف
            if (!string.IsNullOrWhiteSpace(parameters.SearchTerm))
            {
                var term = parameters.SearchTerm.Trim().ToLower();
                AddCriteria(a => a.Name.ToLower().Contains(term)
                                 || a.Description.ToLower().Contains(term));
            }

            // فلترة حسب نوع الكيان
            if (parameters.PropertyTypeId.HasValue)
                AddCriteria(a => a.PropertyTypeAmenities
                    .Any(pta => pta.PropertyTypeId == parameters.PropertyTypeId.Value));

            // التطبيق التصفح
            if (parameters.PageNumber > 0 && parameters.PageSize > 0)
                ApplyPaging(parameters.PageNumber, parameters.PageSize);

            // ترتيب افتراضي بالاسم
            ApplyOrderBy(a => a.Name);
            ApplyNoTracking();
            ApplySplitQuery();
        }
    }
} 