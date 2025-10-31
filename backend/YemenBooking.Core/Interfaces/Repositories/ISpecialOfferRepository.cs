using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Interfaces.Repositories
{
    /// <summary>
    /// واجهة مستودع العروض الخاصة
    /// Special offers repository interface
    /// </summary>
    public interface ISpecialOfferRepository : IRepository<SpecialOffer>
    {
        /// <summary>
        /// الحصول على العروض النشطة
        /// Get active offers
        /// </summary>
        /// <returns>قائمة العروض النشطة</returns>
        Task<List<SpecialOffer>> GetActiveOffersAsync();

        /// <summary>
        /// الحصول على العروض حسب النوع
        /// Get offers by type
        /// </summary>
        /// <param name="offerType">نوع العرض</param>
        /// <returns>قائمة العروض</returns>
        Task<List<SpecialOffer>> GetOffersByTypeAsync(OfferType offerType);

        /// <summary>
        /// الحصول على العروض المرتبطة بعقار معين
        /// Get offers for specific property
        /// </summary>
        /// <param name="propertyId">معرف العقار</param>
        /// <returns>قائمة العروض</returns>
        Task<List<SpecialOffer>> GetOffersByPropertyIdAsync(Guid propertyId);

        /// <summary>
        /// الحصول على عرض بالكود
        /// Get offer by code
        /// </summary>
        /// <param name="offerCode">كود العرض</param>
        /// <returns>العرض إن وجد</returns>
        Task<SpecialOffer?> GetOfferByCodeAsync(string offerCode);

        /// <summary>
        /// التحقق من صحة العرض
        /// Validate offer
        /// </summary>
        /// <param name="offerId">معرف العرض</param>
        /// <param name="amount">المبلغ</param>
        /// <returns>نتيجة التحقق</returns>
        Task<bool> ValidateOfferAsync(Guid offerId, decimal amount);

        /// <summary>
        /// تطبيق العرض (زيادة عداد الاستخدام)
        /// Apply offer (increment usage count)
        /// </summary>
        /// <param name="offerId">معرف العرض</param>
        /// <returns>نتيجة العملية</returns>
        Task<bool> ApplyOfferAsync(Guid offerId);

        /// <summary>
        /// الحصول على العروض المميزة
        /// Get featured offers
        /// </summary>
        /// <param name="count">عدد العروض المطلوبة</param>
        /// <returns>قائمة العروض المميزة</returns>
        Task<List<SpecialOffer>> GetFeaturedOffersAsync(int count = 10);

        /// <summary>
        /// الحصول على العروض المنتهية الصلاحية
        /// Get expired offers
        /// </summary>
        /// <returns>قائمة العروض المنتهية الصلاحية</returns>
        Task<List<SpecialOffer>> GetExpiredOffersAsync();

        /// <summary>
        /// حساب قيمة الخصم للعرض
        /// Calculate discount amount for offer
        /// </summary>
        /// <param name="offerId">معرف العرض</param>
        /// <param name="originalAmount">المبلغ الأصلي</param>
        /// <returns>قيمة الخصم</returns>
        Task<decimal> CalculateDiscountAmountAsync(Guid offerId, decimal originalAmount);

        /// <summary>
        /// الحصول على العروض المتاحة للمستخدم
        /// Get available offers for user
        /// </summary>
        /// <param name="userId">معرف المستخدم</param>
        /// <returns>قائمة العروض المتاحة</returns>
        Task<List<SpecialOffer>> GetAvailableOffersForUserAsync(Guid userId);
    }
}
