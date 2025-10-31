using System;
using System.Linq.Expressions;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Specifications
{
    /// <summary>
    /// معاملات البحث في البلاغات
    /// Report search parameters
    /// </summary>
    public class ReportSearchParameters
    {
        public Guid? ReporterUserId { get; set; }
        public Guid? ReportedUserId { get; set; }
        public Guid? ReportedPropertyId { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }

    /// <summary>
    /// مواصفة البحث في البلاغات
    /// Specification for searching reports
    /// </summary>
    public class ReportSearchSpecification : BaseSpecification<Report>
    {
        public ReportSearchSpecification(ReportSearchParameters parameters)
            : base()
        {
            AddCriteria(r => true);

            if (parameters.ReporterUserId.HasValue)
                AddCriteria(r => r.ReporterUserId == parameters.ReporterUserId.Value);

            if (parameters.ReportedUserId.HasValue)
                AddCriteria(r => r.ReportedUserId == parameters.ReportedUserId.Value);

            if (parameters.ReportedPropertyId.HasValue)
                AddCriteria(r => r.ReportedPropertyId == parameters.ReportedPropertyId.Value);

            if (parameters.PageNumber > 0 && parameters.PageSize > 0)
                ApplyPaging(parameters.PageNumber, parameters.PageSize);

            ApplyOrderBy(r => r.CreatedAt);
            ApplyNoTracking();
            ApplySplitQuery();
        }
    }
} 