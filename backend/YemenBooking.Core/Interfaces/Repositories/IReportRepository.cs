using YemenBooking.Core.Entities;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع البلاغات
/// Report repository interface
/// </summary>
public interface IReportRepository : IRepository<Report>
{
    /// <summary>
    /// إنشاء بلاغ جديد
    /// Create new report
    /// </summary>
    Task<Report> CreateReportAsync(Report report, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على بلاغ بواسطة المعرف
    /// Get report by id
    /// </summary>
    Task<Report?> GetReportByIdAsync(Guid reportId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث بلاغ
    /// Update report
    /// </summary>
    Task<Report> UpdateReportAsync(Report report, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف بلاغ
    /// Delete report
    /// </summary>
    Task<bool> DeleteReportAsync(Guid reportId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على جميع البلاغات مع خيارات الفلترة
    /// Get all reports with optional filters
    /// </summary>
    Task<IEnumerable<Report>> GetReportsAsync(
        Guid? reporterUserId = null,
        Guid? reportedUserId = null,
        Guid? reportedPropertyId = null,
        CancellationToken cancellationToken = default);
} 