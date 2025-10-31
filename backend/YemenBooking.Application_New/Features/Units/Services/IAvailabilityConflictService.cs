using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Application.Features.Units.Services {
    /// <summary>
    /// واجهة خدمة إدارة تعارضات الإتاحة
    /// Availability Conflict Management Service Interface
    /// </summary>
    public interface IAvailabilityConflictService
    {
        /// <summary>
        /// فحص التعارضات المحتملة للوحدة في فترة محددة
        /// Check for potential conflicts for a unit in a specific period
        /// </summary>
        /// <param name="unitId">معرف الوحدة</param>
        /// <param name="startDate">تاريخ البداية</param>
        /// <param name="endDate">تاريخ النهاية</param>
        /// <param name="excludeBookingId">معرف الحجز المستثنى (اختياري)</param>
        /// <returns>نتيجة فحص التعارضات</returns>
        Task<AvailabilityConflictResult> CheckConflictsAsync(
            Guid unitId,
            DateTime startDate,
            DateTime endDate,
            Guid? excludeBookingId = null);

        /// <summary>
        /// محاولة حل التعارضات تلقائياً باستخدام استراتيجية محددة
        /// Attempt to automatically resolve conflicts using a specified strategy
        /// </summary>
        /// <param name="unitId">معرف الوحدة</param>
        /// <param name="startDate">تاريخ البداية</param>
        /// <param name="endDate">تاريخ النهاية</param>
        /// <param name="strategy">استراتيجية الحل</param>
        /// <param name="currentBookingId">معرف الحجز الحالي (اختياري)</param>
        /// <returns>نتيجة محاولة حل التعارضات</returns>
        Task<ConflictResolutionResult> ResolveConflictsAsync(
            Guid unitId,
            DateTime startDate,
            DateTime endDate,
            ConflictResolutionStrategy strategy,
            Guid? currentBookingId = null);

        /// <summary>
        /// الحصول على الفترات المتاحة البديلة للوحدة
        /// Get alternative available periods for the unit
        /// </summary>
        /// <param name="unitId">معرف الوحدة</param>
        /// <param name="preferredStart">تاريخ البداية المفضل</param>
        /// <param name="preferredEnd">تاريخ النهاية المفضل</param>
        /// <param name="maxDaysBefore">أقصى عدد أيام للبحث قبل التاريخ المفضل</param>
        /// <param name="maxDaysAfter">أقصى عدد أيام للبحث بعد التاريخ المفضل</param>
        /// <returns>قائمة بالفترات المتاحة البديلة</returns>
        Task<List<AvailablePeriod>> GetAlternativePeriodsAsync(
            Guid unitId,
            DateTime preferredStart,
            DateTime preferredEnd,
            int maxDaysBefore = 30,
            int maxDaysAfter = 30);
    }
}
