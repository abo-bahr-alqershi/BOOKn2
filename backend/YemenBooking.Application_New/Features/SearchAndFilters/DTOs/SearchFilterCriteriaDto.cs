using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs {
    /// <summary>
    /// معيار فلتر البحث
    /// </summary>
    public class SearchFilterCriteriaDto
    {
        /// <summary>
        /// معرف الحقل
        /// </summary>
        public Guid FieldId { get; set; }

        /// <summary>
        /// معرف الفلتر
        /// </summary>
        public Guid FilterId { get; set; }

        /// <summary>
        /// نوع الفلتر
        /// </summary>
        public string FilterType { get; set; }

        /// <summary>
        /// قيمة الفلتر
        /// </summary>
        public object FilterValue { get; set; }

        /// <summary>
        /// خيارات إضافية للفلتر
        /// </summary>
        public Dictionary<string, object>? FilterOptions { get; set; }
    }
} 