using System;

namespace YemenBooking.Application.Features.Reports.DTOs {
    /// <summary>
    /// عنصر تقرير الإشغال اليومي
    /// Daily occupancy report item
    /// </summary>
    public class OccupancyReportItemDto
    {
        /// <summary>
        /// التاريخ
        /// Date
        /// </summary>
        public DateTime Date { get; set; }

        /// <summary>
        /// عدد الوحدات المشغولة
        /// Occupied units count
        /// </summary>
        public int OccupiedUnits { get; set; }

        /// <summary>
        /// إجمالي عدد الوحدات
        /// Total units count
        /// </summary>
        public int TotalUnits { get; set; }

        /// <summary>
        /// نسبة الإشغال
        /// Occupancy rate
        /// </summary>
        public decimal OccupancyRate { get; set; }
    }
} 