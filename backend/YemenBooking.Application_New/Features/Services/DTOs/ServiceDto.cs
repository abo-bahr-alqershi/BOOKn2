using System;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Services.DTOs {
    /// <summary>
    /// DTO لبيانات خدمة الكيان
    /// DTO for property service data
    /// </summary>
    public class ServiceDto
    {
        /// <summary>
        /// معرف الخدمة
        /// Service identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// معرف الكيان
        /// Property identifier
        /// </summary>
        public Guid PropertyId { get; set; }

        /// <summary>
        /// اسم الكيان
        /// Property name
        /// </summary>
        public string PropertyName { get; set; }

        /// <summary>
        /// اسم الخدمة
        /// Service name
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// أيقونة الخدمة
        /// Service icon
        /// </summary>
        public string Icon { get; set; } = string.Empty;

        /// <summary>
        /// وصف الخدمة
        /// Service description
        /// </summary>
        public string? Description { get; set; }

        /// <summary>
        /// سعر الخدمة
        /// Service price
        /// </summary>
        public MoneyDto Price { get; set; }

        /// <summary>
        /// نموذج التسعير
        /// Pricing model
        /// </summary>
        public PricingModel PricingModel { get; set; }
    }
} 