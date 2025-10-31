using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Bookings.DTOs;

namespace YemenBooking.Application.Infrastructure.Services;

/// <summary>
/// واجهة خدمة التصدير
/// Export service interface
/// </summary>
public interface IExportService
{
    /// <summary>
    /// تصدير الكيانات إلى Excel
    /// Export properties to Excel
    /// </summary>
    Task<ExportResult> ExportPropertiesToExcelAsync(
        IEnumerable<Property> properties,
        string fileName,
        ExportOptions? options = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تصدير الكيانات إلى PDF
    /// Export properties to PDF
    /// </summary>
    Task<ExportResult> ExportPropertiesToPdfAsync(
        IEnumerable<Property> properties,
        string fileName,
        ExportOptions? options = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تصدير الكيانات إلى CSV
    /// Export properties to CSV
    /// </summary>
    Task<ExportResult> ExportPropertiesToCsvAsync(
        IEnumerable<Property> properties,
        string fileName,
        ExportOptions? options = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تصدير الحجوزات إلى Excel
    /// Export bookings to Excel
    /// </summary>
    Task<ExportResult> ExportBookingsToExcelAsync(
        IEnumerable<BookingDto> bookings,
        string fileName,
        ExportOptions? options = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تصدير التقارير
    /// Export reports
    /// </summary>
    Task<ExportResult> ExportReportAsync(
        object reportData,
        string reportType,
        string fileName,
        ExportFormat format,
        ExportOptions? options = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تصدير عام
    /// General export
    /// </summary>
    Task<ExportServiceResult> ExportAsync(
        ExportRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيانات للتصدير
    /// Get properties for export
    /// </summary>
    Task<IEnumerable<Property>> GetPropertiesForExportAsync(
        bool includeInactive = false,
        object? filterCriteria = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تصدير أنواع الكيانات إلى Excel
    /// Export property types to Excel
    /// </summary>
    Task<ExportResult> ExportPropertyTypesToExcelAsync(
        IEnumerable<PropertyType> propertyTypes,
        string fileName,
        ExportOptions? options = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تصدير أنواع الكيانات إلى PDF
    /// Export property types to PDF
    /// </summary>
    Task<ExportResult> ExportPropertyTypesToPdfAsync(
        IEnumerable<PropertyType> propertyTypes,
        string fileName,
        ExportOptions? options = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تصدير أنواع الكيانات إلى CSV
    /// Export property types to CSV
    /// </summary>
    Task<ExportResult> ExportPropertyTypesToCsvAsync(
        IEnumerable<PropertyType> propertyTypes,
        string fileName,
        ExportOptions? options = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على أنواع الكيانات للتصدير
    /// Get property types for export
    /// </summary>
    Task<IEnumerable<PropertyType>> GetPropertyTypesForExportAsync(
        bool includeInactive = false,
        object? filterCriteria = null,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// نتيجة التصدير
/// Export result
/// </summary>
public class ExportResult
{
    public bool IsSuccess { get; set; }
    public string? FilePath { get; set; }
    public string? FileName { get; set; }
    public long FileSizeBytes { get; set; }
    public string? ContentType { get; set; }
    public string? ErrorMessage { get; set; }
    public DateTime ExportedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>
/// خيارات التصدير
/// Export options
/// </summary>
public class ExportOptions
{
    public bool IncludeHeaders { get; set; } = true;
    public string[]? ColumnsToInclude { get; set; }
    public string[]? ColumnsToExclude { get; set; }
    public string? Title { get; set; }
    public string? Description { get; set; }
    public string? Author { get; set; }
    public Dictionary<string, object>? CustomProperties { get; set; }
    public bool CompressOutput { get; set; } = false;
    public string? TemplateFile { get; set; }
}

/// <summary>
/// صيغة التصدير
/// Export format
/// </summary>
public enum ExportFormat
{
    EXCEL,
    PDF,
    CSV,
    JSON,
    XML,
    HTML
}

/// <summary>
/// نتيجة خدمة التصدير
/// Export service result
/// </summary>
public class ExportServiceResult
{
    public bool IsSuccess { get; set; }
    public object? Data { get; set; }
    public string? Message { get; set; }
    public string? Code { get; set; }
}

/// <summary>
/// طلب التصدير
/// Export request  
/// </summary>
public class ExportRequest
{
    public object Data { get; set; } = null!;
    public string Format { get; set; } = "Excel";
    public string FileName { get; set; } = null!;
    public bool IncludeHeaders { get; set; } = true;
    public string[]? Columns { get; set; }
}
