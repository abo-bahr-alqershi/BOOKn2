
namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// بيانات الموقع الجغرافي في الرسائل
    /// DTO for geographic location in chat messages
    /// </summary>
    public class LocationDto
    {
        /// <summary>
        /// خط العرض
        /// Latitude
        /// </summary>
        public double Latitude { get; set; }

        /// <summary>
        /// خط الطول
        /// Longitude
        /// </summary>
        public double Longitude { get; set; }

        /// <summary>
        /// العنوان الوصفي
        /// Address
        /// </summary>
        public string? Address { get; set; }

        /// <summary>
        /// اسم المكان
        /// Place name
        /// </summary>
        public string? PlaceName { get; set; }

        /// <summary>
        /// الدولة
        /// Country
        /// </summary>
        public string? Country { get; set; }

        /// <summary>
        /// المدينة
        /// City
        /// </summary>
        public string? City { get; set; }
    }
} 