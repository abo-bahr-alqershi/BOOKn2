using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace YemenBooking.IndexingTests
{
    /// <summary>
    /// خدمات بسيطة للاختبار - تجنب التعقيدات
    /// </summary>
    
    // واجهات بسيطة للخدمات المطلوبة
    public interface ITestAvailabilityService 
    {
        Task<bool> CheckAvailabilityAsync(Guid unitId, DateTime checkIn, DateTime checkOut);
    }
    
    public interface ITestPricingService
    {
        Task<decimal> CalculatePriceAsync(Guid unitId, DateTime checkIn, DateTime checkOut);
    }
    
    // تطبيقات الواجهات
    public class SimpleAvailabilityService : ITestAvailabilityService
    {
        public Task<bool> CheckAvailabilityAsync(Guid unitId, DateTime checkIn, DateTime checkOut)
        {
            // كل شيء متاح للاختبار
            return Task.FromResult(true);
        }
    }
    
    public class SimplePricingService : ITestPricingService
    {
        public Task<decimal> CalculatePriceAsync(Guid unitId, DateTime checkIn, DateTime checkOut)
        {
            // سعر ثابت للاختبار
            var nights = Math.Max(1, (checkOut - checkIn).Days);
            return Task.FromResult(100m * nights);
        }
    }
}
