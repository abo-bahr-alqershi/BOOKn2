using System;
using System.Linq.Expressions;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Specifications
{
    /// <summary>
    /// معاملات البحث في أنواع الوحدات
    /// Unit type search parameters
    /// </summary>
    public class UnitTypeSearchParameters
    {
        public Guid? PropertyTypeId { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }

    /// <summary>
    /// مواصفة البحث في أنواع الوحدات
    /// Specification for searching unit types
    /// </summary>
    public class UnitTypeSearchSpecification : BaseSpecification<UnitType>
    {
        public UnitTypeSearchSpecification(UnitTypeSearchParameters parameters)
            : base()
        {
            AddCriteria(ut => true);

            if (parameters.PropertyTypeId.HasValue)
                AddCriteria(ut => ut.PropertyTypeId == parameters.PropertyTypeId.Value);

            if (parameters.PageNumber > 0 && parameters.PageSize > 0)
                ApplyPaging(parameters.PageNumber, parameters.PageSize);

            ApplyOrderBy(ut => ut.Name);
            ApplyNoTracking();
            ApplySplitQuery();
        }
    }
} 