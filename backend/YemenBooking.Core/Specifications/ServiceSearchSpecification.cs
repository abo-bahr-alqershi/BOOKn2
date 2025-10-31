using System;
using System.Linq.Expressions;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Specifications
{
    /// <summary>
    /// معاملات البحث في خدمات الكيان
    /// Service search parameters
    /// </summary>
    public class ServiceSearchParameters
    {
        public string? ServiceType { get; set; }
        public Guid? PropertyId { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }

    /// <summary>
    /// مواصفة البحث في خدمات الكيان
    /// Specification for searching property services
    /// </summary>
    public class ServiceSearchSpecification : BaseSpecification<PropertyService>
    {
        public ServiceSearchSpecification(ServiceSearchParameters parameters)
            : base()
        {
            AddCriteria(s => true);

            if (!string.IsNullOrWhiteSpace(parameters.ServiceType))
            {
                var term = parameters.ServiceType.Trim().ToLower();
                AddCriteria(s => s.Name.ToLower().Contains(term));
            }

            if (parameters.PropertyId.HasValue)
                AddCriteria(s => s.PropertyId == parameters.PropertyId.Value);

            if (parameters.PageNumber > 0 && parameters.PageSize > 0)
                ApplyPaging(parameters.PageNumber, parameters.PageSize);

            ApplyOrderBy(s => s.Name);
            ApplyNoTracking();
            ApplySplitQuery();
        }
    }
} 