using System.Collections.Generic;

namespace YemenBooking.Application.Features.Policies.DTOs {
    /// <summary>
    /// DTO لإحصائيات السياسات
    /// DTO for policy statistics
    /// </summary>
    public class PolicyStatsDto
    {
        /// <summary>
        /// إجمالي عدد السياسات
        /// Total policies count
        /// </summary>
        public int TotalPolicies { get; set; }

        /// <summary>
        /// عدد السياسات النشطة
        /// Active policies count
        /// </summary>
        public int ActivePolicies { get; set; }

        /// <summary>
        /// عدد السياسات حسب النوع
        /// Policies count by type
        /// </summary>
        public int PoliciesByType { get; set; }

        /// <summary>
        /// توزيع أنواع السياسات
        /// Policy type distribution
        /// </summary>
        public Dictionary<string, int> PolicyTypeDistribution { get; set; } = new();

        /// <summary>
        /// متوسط نافذة الإلغاء
        /// Average cancellation window
        /// </summary>
        public double AverageCancellationWindow { get; set; }
    }
}
