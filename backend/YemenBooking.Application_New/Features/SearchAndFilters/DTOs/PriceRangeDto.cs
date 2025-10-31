using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs {
    /// <summary>
    /// النطاق السعري
    /// </summary>
    public class PriceRangeDto
    {
        /// <summary>
        /// الحد الأدنى للسعر
        /// </summary>
        public decimal MinPrice { get; set; }

        /// <summary>
        /// الحد الأقصى للسعر
        /// </summary>
        public decimal MaxPrice { get; set; }

        /// <summary>
        /// متوسط السعر
        /// </summary>
        public decimal AveragePrice { get; set; }
    }
}