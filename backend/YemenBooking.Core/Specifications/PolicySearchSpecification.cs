using System;
using System.Linq.Expressions;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Specifications
{
    /// <summary>
    /// معاملات البحث في سياسات الكيانات
    /// Policy search parameters
    /// </summary>
    public class PolicySearchParameters
    {
        public string? PolicyType { get; set; }
        public Guid? PropertyId { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }

    /// <summary>
    /// مواصفة البحث في سياسات الكيانات
    /// Specification for searching property policies
    /// </summary>
    public class PolicySearchSpecification : BaseSpecification<PropertyPolicy>
    {
        public PolicySearchSpecification(PolicySearchParameters parameters)
            : base()
        {
            AddCriteria(po => true);

            if (!string.IsNullOrWhiteSpace(parameters.PolicyType))
            {
                var t = parameters.PolicyType.Trim().ToLower();
                AddCriteria(po => po.Type.ToString().ToLower() == t);
            }

            if (parameters.PropertyId.HasValue)
                AddCriteria(po => po.PropertyId == parameters.PropertyId.Value);

            if (parameters.PageNumber > 0 && parameters.PageSize > 0)
                ApplyPaging(parameters.PageNumber, parameters.PageSize);

            ApplyOrderBy(po => po.Type);
            ApplyNoTracking();
            ApplySplitQuery();
        }
    }
} 