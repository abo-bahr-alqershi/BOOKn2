using System;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// DTO لإحصائيات صور الكيان
    /// DTO for property image statistics
    /// </summary>
    public class PropertyImageStatsDto
    {
        /// <summary>
        /// معرف الكيان
        /// Property identifier
        /// </summary>
        public Guid PropertyId { get; set; }

        /// <summary>
        /// إجمالي عدد الصور
        /// Total number of images
        /// </summary>
        public int TotalImages { get; set; }

        /// <summary>
        /// عدد الصور المعلقة
        /// Number of pending images
        /// </summary>
        public int PendingCount { get; set; }

        /// <summary>
        /// عدد الصور الموافق عليها
        /// Number of approved images
        /// </summary>
        public int ApprovedCount { get; set; }

        /// <summary>
        /// عدد الصور المرفوضة
        /// Number of rejected images
        /// </summary>
        public int RejectedCount { get; set; }
    }
} 