using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع الأسئلة الشائعة
/// FAQ repository interface
/// </summary>
public interface IFAQRepository
{
    /// <summary>
    /// الحصول على جميع الأسئلة الشائعة النشطة
    /// Get all active FAQs
    /// </summary>
    /// <param name="language">اللغة</param>
    /// <param name="category">الفئة (اختيارية)</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة الأسئلة الشائعة</returns>
    Task<IEnumerable<FAQ>> GetActiveFAQsAsync(string language = "ar", string? category = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الأسئلة الشائعة مجمعة حسب الفئة
    /// Get FAQs grouped by category
    /// </summary>
    /// <param name="language">اللغة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قاموس الفئات والأسئلة</returns>
    Task<Dictionary<string, List<FAQ>>> GetFAQsGroupedByCategoryAsync(string language = "ar", CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على سؤال شائع بالمعرف
    /// Get FAQ by ID
    /// </summary>
    /// <param name="id">معرف السؤال</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>السؤال الشائع أو null</returns>
    Task<FAQ?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// البحث في الأسئلة الشائعة
    /// Search FAQs
    /// </summary>
    /// <param name="searchTerm">مصطلح البحث</param>
    /// <param name="language">اللغة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة النتائج</returns>
    Task<IEnumerable<FAQ>> SearchFAQsAsync(string searchTerm, string language = "ar", CancellationToken cancellationToken = default);

    /// <summary>
    /// إضافة سؤال شائع جديد
    /// Add new FAQ
    /// </summary>
    /// <param name="faq">السؤال الشائع</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>السؤال المضاف</returns>
    Task<FAQ> AddAsync(FAQ faq, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث سؤال شائع
    /// Update FAQ
    /// </summary>
    /// <param name="faq">السؤال الشائع</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>السؤال المحدث</returns>
    Task<FAQ> UpdateAsync(FAQ faq, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف سؤال شائع
    /// Delete FAQ
    /// </summary>
    /// <param name="id">معرف السؤال</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>true إذا تم الحذف بنجاح</returns>
    Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// زيادة عدد المشاهدات
    /// Increment view count
    /// </summary>
    /// <param name="id">معرف السؤال</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>true إذا تم التحديث بنجاح</returns>
    Task<bool> IncrementViewCountAsync(Guid id, CancellationToken cancellationToken = default);
}
