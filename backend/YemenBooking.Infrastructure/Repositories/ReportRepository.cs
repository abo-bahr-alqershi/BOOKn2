using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories;

/// <summary>
/// مستودع إدارة البلاغات
/// Repository for managing reports
/// </summary>
public class ReportRepository : BaseRepository<Report>, IReportRepository
{
    public ReportRepository(YemenBookingDbContext context) : base(context)
    {
    }

    public async Task<Report> CreateReportAsync(Report report, CancellationToken cancellationToken = default)
    {
        _context.Reports.Add(report);
        await _context.SaveChangesAsync(cancellationToken);
        return report;
    }

    public async Task<Report?> GetReportByIdAsync(Guid reportId, CancellationToken cancellationToken = default)
    {
        return await _context.Reports
            .Include(r => r.ReporterUser)
            .Include(r => r.ReportedUser)
            .Include(r => r.ReportedProperty)
            .FirstOrDefaultAsync(r => r.Id == reportId, cancellationToken);
    }

    public async Task<IEnumerable<Report>> GetReportsAsync(Guid? reporterUserId = null, Guid? reportedUserId = null, Guid? reportedPropertyId = null, CancellationToken cancellationToken = default)
    {
        var query = _context.Reports.AsQueryable();
        if (reporterUserId.HasValue)
            query = query.Where(r => r.ReporterUserId == reporterUserId.Value);
        if (reportedUserId.HasValue)
            query = query.Where(r => r.ReportedUserId == reportedUserId.Value);
        if (reportedPropertyId.HasValue)
            query = query.Where(r => r.ReportedPropertyId == reportedPropertyId.Value);
        return await query
            .Include(r => r.ReporterUser)
            .Include(r => r.ReportedUser)
            .Include(r => r.ReportedProperty)
            .ToListAsync(cancellationToken);
    }

    public async Task<Report> UpdateReportAsync(Report report, CancellationToken cancellationToken = default)
    {
        _context.Reports.Update(report);
        await _context.SaveChangesAsync(cancellationToken);
        return report;
    }

    public async Task<bool> DeleteReportAsync(Guid reportId, CancellationToken cancellationToken = default)
    {
        var report = await _context.Reports.FindAsync(new object[]{reportId}, cancellationToken);
        if (report == null) return false;
        _context.Reports.Remove(report);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }
} 