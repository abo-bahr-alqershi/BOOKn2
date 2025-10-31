namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// DTO لوجهة مشهورة
    /// DTO for popular destination
    /// </summary>
    public class DestinationDto
    {
        /// <summary>
        /// اسم المدينة
        /// City name
        /// </summary>
        public string City { get; set; }

        /// <summary>
        /// عدد المشاهدات
        /// View count
        /// </summary>
        public int ViewCount { get; set; }
    }
} 