using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs {
    /// <summary>
    /// طلب البحث عن الإتاحة
    /// DTO for availability search request
    /// </summary>
    public class AvailabilitySearchRequest
    {
        /// <summary>
        /// قائمة معرفات الوحدات
        /// List of unit IDs
        /// </summary>
        public IEnumerable<Guid>? UnitIds { get; set; }

        /// <summary>
        /// معرف الكيان
        /// Property ID
        /// </summary>
        public Guid? PropertyId { get; set; }

        /// <summary>
        /// تاريخ البداية
        /// Start date
        /// </summary>
        public DateTime? StartDate { get; set; }

        /// <summary>
        /// تاريخ النهاية
        /// End date
        /// </summary>
        public DateTime? EndDate { get; set; }

        /// <summary>
        /// قائمة حالات الإتاحة
        /// Availability statuses
        /// </summary>
        [JsonPropertyName("status")]
        public IEnumerable<string>? Statuses { get; set; }

        /// <summary>
        /// تضمين التعارضات
        /// Include conflicts
        /// </summary>
        public bool? IncludeConflicts { get; set; }
    }
} 