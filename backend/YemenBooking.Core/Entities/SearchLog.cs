using System;
using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Core.Entities
{
    /// <summary>
    /// سجل عمليات البحث من قبل المستخدمين
    /// Search logs by users
    /// </summary>
    [Display(Name = "سجل عمليات البحث من قبل المستخدمين")]
    public class SearchLog : BaseEntity<Guid>
    {
        /// <summary>
        /// معرف المستخدم الذي قام بالبحث
        /// User identifier who performed the search
        /// </summary>
        [Display(Name = "معرف المستخدم الذي قام بالبحث")]
        public Guid UserId { get; set; }

        /// <summary>
        /// نوع البحث (Property أو Unit)
        /// Search type (Property or Unit)
        /// </summary>
        [Display(Name = "نوع البحث")]
        public string SearchType { get; set; } = string.Empty;

        /// <summary>
        /// معايير البحث والفلترة بصيغة JSON
        /// Search and filter criteria in JSON format
        /// </summary>
        [Display(Name = "معايير البحث والفلترة")]
        public string CriteriaJson { get; set; } = "{}";

        /// <summary>
        /// عدد النتائج المرجعة
        /// Number of results returned
        /// </summary>
        [Display(Name = "عدد النتائج المرجعة")]
        public int ResultCount { get; set; }

        /// <summary>
        /// رقم الصفحة
        /// Page number
        /// </summary>
        [Display(Name = "رقم الصفحة")]
        public int PageNumber { get; set; }

        /// <summary>
        /// حجم الصفحة
        /// Page size
        /// </summary>
        [Display(Name = "حجم الصفحة")]
        public int PageSize { get; set; }
    }
} 