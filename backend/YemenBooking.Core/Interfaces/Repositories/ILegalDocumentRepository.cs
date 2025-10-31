using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع المستندات القانونية
/// Legal document repository interface
/// </summary>
public interface ILegalDocumentRepository
{
    /// <summary>
    /// الحصول على مستند قانوني حسب النوع واللغة
    /// Get legal document by type and language
    /// </summary>
    /// <param name="type">نوع المستند</param>
    /// <param name="language">اللغة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>المستند القانوني أو null</returns>
    Task<LegalDocument?> GetByTypeAndLanguageAsync(LegalDocumentType type, string language, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على جميع المستندات القانونية حسب النوع
    /// Get all legal documents by type
    /// </summary>
    /// <param name="type">نوع المستند</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة المستندات القانونية</returns>
    Task<IEnumerable<LegalDocument>> GetByTypeAsync(LegalDocumentType type, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مستند قانوني بالمعرف
    /// Get legal document by ID
    /// </summary>
    /// <param name="id">معرف المستند</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>المستند القانوني أو null</returns>
    Task<LegalDocument?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// إضافة مستند قانوني جديد
    /// Add new legal document
    /// </summary>
    /// <param name="document">المستند القانوني</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>المستند المضاف</returns>
    Task<LegalDocument> AddAsync(LegalDocument document, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث مستند قانوني
    /// Update legal document
    /// </summary>
    /// <param name="document">المستند القانوني</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>المستند المحدث</returns>
    Task<LegalDocument> UpdateAsync(LegalDocument document, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف مستند قانوني
    /// Delete legal document
    /// </summary>
    /// <param name="id">معرف المستند</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>true إذا تم الحذف بنجاح</returns>
    Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
