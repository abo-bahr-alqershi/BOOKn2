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

public class SectionImageRepository : BaseRepository<SectionImage>, ISectionImageRepository
{
    public SectionImageRepository(YemenBookingDbContext context) : base(context) { }

    public async Task<SectionImage> CreateAsync(SectionImage image, CancellationToken cancellationToken = default)
    {
        await _dbSet.AddAsync(image, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        return image;
    }

    public new async Task<SectionImage?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => await _dbSet.FirstOrDefaultAsync(x => x.Id == id && !x.IsDeleted, cancellationToken);

    public async Task<SectionImage> UpdateAsync(SectionImage image, CancellationToken cancellationToken = default)
    {
        _dbSet.Update(image);
        await _context.SaveChangesAsync(cancellationToken);
        return image;
    }

    public async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await GetByIdAsync(id, cancellationToken);
        if (entity == null) return false;
        entity.IsDeleted = true;
        entity.DeletedAt = DateTime.UtcNow;
        _dbSet.Update(entity);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<IEnumerable<SectionImage>> GetBySectionIdAsync(Guid sectionId, CancellationToken cancellationToken = default)
        => await _dbSet.Where(x => x.SectionId == sectionId && !x.IsDeleted)
            .OrderBy(x => x.DisplayOrder).ThenBy(x => x.UploadedAt)
            .ToListAsync(cancellationToken);

    public async Task<bool> UpdateDisplayOrdersAsync(IEnumerable<(Guid imageId, int displayOrder)> assignments, CancellationToken cancellationToken = default)
    {
        var ids = assignments.Select(a => a.imageId).ToList();
        var items = await _dbSet.Where(x => ids.Contains(x.Id)).ToListAsync(cancellationToken);
        var map = assignments.ToDictionary(a => a.imageId, a => a.displayOrder);
        foreach (var i in items) if (map.TryGetValue(i.Id, out var order)) i.DisplayOrder = order;
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> UpdateMainImageStatusAsync(Guid imageId, bool isMain, CancellationToken cancellationToken = default)
    {
        var current = await _dbSet.FirstOrDefaultAsync(x => x.Id == imageId, cancellationToken);
        if (current == null) return false;
        var sectionId = current.SectionId;
        var siblings = await _dbSet.Where(x => x.SectionId == sectionId).ToListAsync(cancellationToken);
        foreach (var s in siblings) s.IsMainImage = s.Id == imageId ? isMain : false;
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<IEnumerable<SectionImage>> GetByTempKeyAsync(string tempKey, CancellationToken cancellationToken = default)
        => await _dbSet.Where(x => x.TempKey == tempKey && !x.IsDeleted)
            .OrderBy(x => x.CreatedAt)
            .ToListAsync(cancellationToken);
}

