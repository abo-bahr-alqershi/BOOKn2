namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// إحصاءات تقييم الكيان
    /// Property rating stats DTO
    /// </summary>
    public class PropertyRatingStatsDto
    {
        /// <summary>
        /// متوسط تقييم الكيان
        /// Average rating of the property
        /// </summary>
        public double AverageRating { get; set; }

        /// <summary>
        /// إجمالي عدد التقييمات
        /// Total number of reviews
        /// </summary>
        public int TotalReviews { get; set; }
    }
} 