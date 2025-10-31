using System;
using System.Text.Json.Serialization;
using YemenBooking.Application.Features.Services.DTOs;

namespace YemenBooking.Application.Features.Bookings.DTOs {
    /// <summary>
    /// DTO لخدمة مرتبطة بالحجز
    /// BookingDto service DTO
    /// </summary>
    public class BookingServiceDto
    {
        /// <summary>
        /// معرف الخدمة
        /// Service identifier
        /// </summary>
        public Guid Id { get; set; }

        [JsonPropertyName("serviceId")]
        public Guid ServiceId { get => Id; set => Id = value; }

        /// <summary>
        /// اسم الخدمة
        /// Service name
        /// </summary>
        public string Name { get; set; } = string.Empty;

        [JsonPropertyName("serviceName")]
        public string ServiceName { get => Name; set => Name = value; }

        /// <summary>
        /// الكمية
        /// Quantity
        /// </summary>
        public int Quantity { get; set; }

        /// <summary>
        /// السعر الإجمالي للخدمة
        /// Total price
        /// </summary>
        public decimal TotalPrice { get; set; }

        /// <summary>
        /// العملة
        /// Currency
        /// </summary>
        public string Currency { get; set; } = "YER";
    }
}
