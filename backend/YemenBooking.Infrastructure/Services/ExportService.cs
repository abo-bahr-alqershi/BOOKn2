using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Infrastructure.Services;
using System.IO;
using System.Linq;
using ClosedXML.Excel;
using CsvHelper;
using CsvHelper.Configuration;
using System.Globalization;
using QuestPDF.Fluent;
using QuestPDF.Infrastructure;
using QuestPDF.Helpers;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Infrastructure.Data.Context;
using System.Text.Json;
using YemenBooking.Application.Features.Bookings.DTOs;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة التصدير
    /// Export service implementation
    /// </summary>
    public class ExportService : IExportService
    {
        private readonly ILogger<ExportService> _logger;
        private readonly YemenBookingDbContext _dbContext;
        private readonly string _exportFolder = Path.Combine(Directory.GetCurrentDirectory(), "Exports");

        public ExportService(ILogger<ExportService> logger, YemenBookingDbContext dbContext)
        {
            _logger = logger;
            _dbContext = dbContext;
            if (!Directory.Exists(_exportFolder)) Directory.CreateDirectory(_exportFolder);
        }

        /// <inheritdoc />
        public async Task<ExportResult> ExportPropertiesToExcelAsync(IEnumerable<Property> properties, string fileName, ExportOptions? options = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تصدير الكيانات إلى Excel: {FileName}", fileName);
            try
            {
                var data = properties.ToList();
                using var workbook = new XLWorkbook();
                var sheet = workbook.Worksheets.Add("Properties");
                // رؤوس الأعمدة
                var headers = new[] { "Id", "Name", "Address", "City", "StarRating", "IsApproved", "CreatedAt", "ViewCount", "BookingCount" };
                for (int i = 0; i < headers.Length; i++) sheet.Cell(1, i + 1).Value = headers[i];
                // البيانات
                for (int idx = 0; idx < data.Count; idx++)
                {
                    var p = data[idx];
                    var row = idx + 2;
                    sheet.Cell(row, 1).Value = p.Id.ToString();
                    sheet.Cell(row, 2).Value = p.Name;
                    sheet.Cell(row, 3).Value = p.Address;
                    sheet.Cell(row, 4).Value = p.City;
                    sheet.Cell(row, 5).Value = p.StarRating;
                    sheet.Cell(row, 6).Value = p.IsApproved;
                    sheet.Cell(row, 7).Value = p.CreatedAt;
                    sheet.Cell(row, 8).Value = p.ViewCount;
                    sheet.Cell(row, 9).Value = p.BookingCount;
                }
                var path = Path.Combine(_exportFolder, fileName);
                workbook.SaveAs(path);
                var info = new FileInfo(path);
                return new ExportResult
                {
                    IsSuccess = true,
                    FilePath = path,
                    FileName = fileName,
                    FileSizeBytes = info.Length,
                    ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    ExportedAt = info.CreationTimeUtc
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تصدير الكيانات إلى Excel");
                return new ExportResult { IsSuccess = false, ErrorMessage = ex.Message };
            }
        }

        /// <inheritdoc />
        public async Task<ExportResult> ExportPropertiesToPdfAsync(IEnumerable<Property> properties, string fileName, ExportOptions? options = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تصدير الكيانات إلى PDF: {FileName}", fileName);
            try
            {
                var data = properties.ToList();
                var path = Path.Combine(_exportFolder, fileName);
                // إنشاء مستند PDF
                Document.Create(container =>
                {
                    container.Page(page =>
                    {
                        page.Size(PageSizes.A4);
                        page.Margin(20);
                        page.Content().Column(col =>
                        {
                            col.Item().Text("تصدير الكيانات").FontSize(20).Bold();
                            col.Item().Table(table =>
                            {
                                // تعريف الأعمدة
                                table.ColumnsDefinition(def =>
                                {
                                    def.RelativeColumn(); def.RelativeColumn(); def.RelativeColumn(); def.RelativeColumn();
                                    def.RelativeColumn(); def.RelativeColumn(); def.RelativeColumn(); def.RelativeColumn(); def.RelativeColumn();
                                });
                                // رؤوس الأعمدة
                                var headers = new[] { "Id", "Name", "Address", "City", "StarRating", "IsApproved", "CreatedAt", "ViewCount", "BookingCount" };
                                table.Header(headerRow =>
                                {
                                    foreach (var h in headers)
                                        headerRow.Cell().Text(h).SemiBold();
                                });
                                // صفوف البيانات
                                foreach (var p in data)
                                {
                                    table.Cell().Text(p.Id.ToString());
                                    table.Cell().Text(p.Name);
                                    table.Cell().Text(p.Address);
                                    table.Cell().Text(p.City);
                                    table.Cell().Text(p.StarRating.ToString());
                                    table.Cell().Text(p.IsApproved.ToString());
                                    table.Cell().Text(p.CreatedAt.ToString("o"));
                                    table.Cell().Text(p.ViewCount.ToString());
                                    table.Cell().Text(p.BookingCount.ToString());
                                }
                            });
                        });
                    });
                }).GeneratePdf(path);
                var info = new FileInfo(path);
                return new ExportResult
                {
                    IsSuccess = true,
                    FilePath = path,
                    FileName = fileName,
                    FileSizeBytes = info.Length,
                    ContentType = "application/pdf",
                    ExportedAt = info.CreationTimeUtc
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تصدير الكيانات إلى PDF");
                return new ExportResult { IsSuccess = false, ErrorMessage = ex.Message };
            }
        }

        /// <inheritdoc />
        public async Task<ExportResult> ExportPropertiesToCsvAsync(IEnumerable<Property> properties, string fileName, ExportOptions? options = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تصدير الكيانات إلى CSV: {FileName}", fileName);
            try
            {
                var data = properties;
                var path = Path.Combine(_exportFolder, fileName);
                await using var writer = new StreamWriter(path);
                await using var csv = new CsvWriter(writer, new CsvConfiguration(CultureInfo.InvariantCulture));
                csv.WriteRecords(data);
                await writer.FlushAsync();
                var info = new FileInfo(path);
                return new ExportResult
                {
                    IsSuccess = true,
                    FilePath = path,
                    FileName = fileName,
                    FileSizeBytes = info.Length,
                    ContentType = "text/csv",
                    ExportedAt = info.CreationTimeUtc
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تصدير الكيانات إلى CSV");
                return new ExportResult { IsSuccess = false, ErrorMessage = ex.Message };
            }
        }

        /// <inheritdoc />
        public async Task<ExportResult> ExportBookingsToExcelAsync(IEnumerable<BookingDto> bookings, string fileName, ExportOptions? options = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تصدير الحجوزات إلى Excel: {FileName}", fileName);
            try
            {
                var data = bookings.ToList();
                using var workbook = new XLWorkbook();
                var sheet = workbook.Worksheets.Add("Bookings");
                var headers = new[]
                {
                    "Id",
                    "UserId",
                    "UnitId",
                    "UserName",
                    "UnitName",
                    "CheckIn",
                    "CheckOut",
                    "GuestsCount",
                    "TotalPrice",
                    "Currency",
                    "Status",
                    "BookedAt"
                };
                for (int i = 0; i < headers.Length; i++) sheet.Cell(1, i + 1).Value = headers[i];
                for (int idx = 0; idx < data.Count; idx++)
                {
                    var b = data[idx];
                    var row = idx + 2;
                    sheet.Cell(row, 1).Value = b.Id.ToString();
                    sheet.Cell(row, 2).Value = b.UserId.ToString();
                    sheet.Cell(row, 3).Value = b.UnitId.ToString();
                    sheet.Cell(row, 4).Value = b.UserName;
                    sheet.Cell(row, 5).Value = b.UnitName;
                    sheet.Cell(row, 6).Value = b.CheckIn;
                    sheet.Cell(row, 7).Value = b.CheckOut;
                    sheet.Cell(row, 8).Value = b.GuestsCount;
                    sheet.Cell(row, 9).Value = b.TotalPrice?.Amount ?? 0m;
                    sheet.Cell(row, 10).Value = b.TotalPrice?.Currency ?? string.Empty;
                    sheet.Cell(row, 11).Value = b.Status.ToString();
                    sheet.Cell(row, 12).Value = b.BookedAt;
                }
                var path = Path.Combine(_exportFolder, fileName);
                workbook.SaveAs(path);
                var info = new FileInfo(path);
                return new ExportResult
                {
                    IsSuccess = true,
                    FilePath = path,
                    FileName = fileName,
                    FileSizeBytes = info.Length,
                    ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    ExportedAt = info.CreationTimeUtc
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تصدير الحجوزات إلى Excel");
                return new ExportResult { IsSuccess = false, ErrorMessage = ex.Message };
            }
        }

        /// <inheritdoc />
        public async Task<ExportResult> ExportReportAsync(object reportData, string reportType, string fileName, ExportFormat format, ExportOptions? options = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تصدير تقرير {ReportType} بصيغة {Format}: {FileName}", reportType, format, fileName);
            try
            {
                var path = Path.Combine(_exportFolder, fileName);
                var content = JsonSerializer.Serialize(reportData, new JsonSerializerOptions { WriteIndented = true });
                await File.WriteAllTextAsync(path, content, cancellationToken);
                var info = new FileInfo(path);
                return new ExportResult
                {
                    IsSuccess = true,
                    FilePath = path,
                    FileName = fileName,
                    FileSizeBytes = info.Length,
                    ContentType = "application/json",
                    ExportedAt = info.CreationTimeUtc
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تصدير التقرير");
                return new ExportResult { IsSuccess = false, ErrorMessage = ex.Message };
            }
        }

        /// <inheritdoc />
        public async Task<ExportServiceResult> ExportAsync(ExportRequest request, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تصدير عام بناءً على الطلب: {FileName}", request.FileName);
            var exportOptions = new ExportOptions
            {
                IncludeHeaders = request.IncludeHeaders,
                ColumnsToInclude = request.Columns
            };
            var exportResult = await ExportReportAsync(request.Data, request.Format, request.FileName, (ExportFormat)Enum.Parse(typeof(ExportFormat), request.Format, true), exportOptions, cancellationToken);
            return new ExportServiceResult
            {
                IsSuccess = exportResult.IsSuccess,
                Data = exportResult,
                Message = exportResult.ErrorMessage,
                Code = null
            };
        }

        /// <inheritdoc />
        public async Task<IEnumerable<Property>> GetPropertiesForExportAsync(bool includeInactive = false, object? filterCriteria = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على الكيانات للتصدير (IncludeInactive: {IncludeInactive})", includeInactive);
            var query = _dbContext.Properties.AsQueryable();
            if (!includeInactive)
                query = query.Where(p => p.IsApproved);
            return await query.ToListAsync(cancellationToken);
        }

        /// <inheritdoc />
        public async Task<ExportResult> ExportPropertyTypesToExcelAsync(IEnumerable<PropertyType> propertyTypes, string fileName, ExportOptions? options = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تصدير أنواع الكيانات إلى Excel: {FileName}", fileName);
            try
            {
                var data = propertyTypes.ToList();
                using var workbook = new XLWorkbook();
                var sheet = workbook.Worksheets.Add("PropertyTypes");
                var headers = new[] { "Id", "Name", "Description", "DefaultAmenities" };
                for (int i = 0; i < headers.Length; i++) sheet.Cell(1, i + 1).Value = headers[i];
                for (int idx = 0; idx < data.Count; idx++)
                {
                    var t = data[idx];
                    var row = idx + 2;
                    sheet.Cell(row, 1).Value = t.Id.ToString();
                    sheet.Cell(row, 2).Value = t.Name;
                    sheet.Cell(row, 3).Value = t.Description;
                    sheet.Cell(row, 4).Value = t.DefaultAmenities;
                }
                var path = Path.Combine(_exportFolder, fileName);
                workbook.SaveAs(path);
                var info = new FileInfo(path);
                return new ExportResult { IsSuccess = true, FilePath = path, FileName = fileName, FileSizeBytes = info.Length, ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", ExportedAt = info.CreationTimeUtc };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تصدير أنواع الكيانات إلى Excel");
                return new ExportResult { IsSuccess = false, ErrorMessage = ex.Message };
            }
        }

        /// <inheritdoc />
        public async Task<ExportResult> ExportPropertyTypesToPdfAsync(IEnumerable<PropertyType> propertyTypes, string fileName, ExportOptions? options = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تصدير أنواع الكيانات إلى PDF: {FileName}", fileName);
            try
            {
                var data = propertyTypes.ToList();
                var path = Path.Combine(_exportFolder, fileName);
                Document.Create(container =>
                {
                    container.Page(page =>
                    {
                        page.Size(PageSizes.A4);
                        page.Margin(20);
                        page.Content().Column(col =>
                        {
                            col.Item().Text("تصدير أنواع الكيانات").FontSize(20).Bold();
                            col.Item().Table(table =>
                            {
                                table.ColumnsDefinition(def => { def.RelativeColumn(); def.RelativeColumn(); def.RelativeColumn(); def.RelativeColumn(); });
                                var headers = new[] { "Id", "Name", "Description", "DefaultAmenities" };
                                table.Header(hr => { foreach (var h in headers) hr.Cell().Text(h).SemiBold(); });
                                foreach (var t in data)
                                {
                                    table.Cell().Text(t.Id.ToString());
                                    table.Cell().Text(t.Name);
                                    table.Cell().Text(t.Description);
                                    table.Cell().Text(t.DefaultAmenities);
                                }
                            });
                        });
                    });
                }).GeneratePdf(path);
                var info = new FileInfo(path);
                return new ExportResult { IsSuccess = true, FilePath = path, FileName = fileName, FileSizeBytes = info.Length, ContentType = "application/pdf", ExportedAt = info.CreationTimeUtc };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تصدير أنواع الكيانات إلى PDF");
                return new ExportResult { IsSuccess = false, ErrorMessage = ex.Message };
            }
        }

        /// <inheritdoc />
        public async Task<ExportResult> ExportPropertyTypesToCsvAsync(IEnumerable<PropertyType> propertyTypes, string fileName, ExportOptions? options = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تصدير أنواع الكيانات إلى CSV: {FileName}", fileName);
            try
            {
                var path = Path.Combine(_exportFolder, fileName);
                await using var writer = new StreamWriter(path);
                await using var csv = new CsvWriter(writer, new CsvConfiguration(CultureInfo.InvariantCulture));
                csv.WriteRecords(propertyTypes);
                await writer.FlushAsync();
                var info = new FileInfo(path);
                return new ExportResult { IsSuccess = true, FilePath = path, FileName = fileName, FileSizeBytes = info.Length, ContentType = "text/csv", ExportedAt = info.CreationTimeUtc };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تصدير أنواع الكيانات إلى CSV");
                return new ExportResult { IsSuccess = false, ErrorMessage = ex.Message };
            }
        }

        /// <inheritdoc />
        public async Task<IEnumerable<PropertyType>> GetPropertyTypesForExportAsync(bool includeInactive = false, object? filterCriteria = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على أنواع الكيانات للتصدير (IncludeInactive: {IncludeInactive})", includeInactive);
            return await _dbContext.PropertyTypes.ToListAsync(cancellationToken);
        }
    }
} 