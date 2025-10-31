using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories;

/// <summary>
/// تنفيذ مستودع صور الكيانات
/// Property image repository implementation
/// </summary>
public class PropertyImageRepository : BaseRepository<PropertyImage>, IPropertyImageRepository
{
    public PropertyImageRepository(YemenBookingDbContext context) : base(context) { }

    public async Task<PropertyImage> CreatePropertyImageAsync(PropertyImage propertyImage, CancellationToken cancellationToken = default)
    {
        await _dbSet.AddAsync(propertyImage, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        return propertyImage;
    }

    public async Task<PropertyImage?> GetPropertyImageByIdAsync(Guid imageId, CancellationToken cancellationToken = default)
        => await _dbSet
            .Include(pi => pi.Property)
            .Include(pi => pi.Unit)
            .FirstOrDefaultAsync(pi => pi.Id == imageId && !pi.IsDeleted, cancellationToken);

    public async Task<PropertyImage> UpdatePropertyImageAsync(PropertyImage propertyImage, CancellationToken cancellationToken = default)
    {
        _dbSet.Update(propertyImage);
        await _context.SaveChangesAsync(cancellationToken);
        return propertyImage;
    }

    public async Task<bool> DeletePropertyImageAsync(Guid imageId, CancellationToken cancellationToken = default)
    {
        var image = await GetPropertyImageByIdAsync(imageId, cancellationToken);
        if (image == null) return false;

        // Soft delete
        image.IsDeleted = true;
        image.DeletedAt = DateTime.UtcNow;
        
        _dbSet.Update(image);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    /// <summary>
    /// حذف دائم لصورة واحدة (تجاوز الحذف الناعم والفلتر)
    /// </summary>
    public async Task<bool> HardDeleteAsync(Guid imageId, CancellationToken cancellationToken = default)
    {
        var image = await _dbSet.IgnoreQueryFilters().FirstOrDefaultAsync(pi => pi.Id == imageId, cancellationToken);
        if (image == null) return false;
        _dbSet.Remove(image);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    /// <summary>
    /// حذف دائم لكل صور العقار
    /// </summary>
    public async Task<int> HardDeleteByPropertyIdAsync(Guid propertyId, CancellationToken cancellationToken = default)
    {
        var images = await _dbSet.IgnoreQueryFilters()
            .Where(pi => pi.PropertyId == propertyId)
            .ToListAsync(cancellationToken);
        if (images.Count == 0) return 0;
        _dbSet.RemoveRange(images);
        return await _context.SaveChangesAsync(cancellationToken);
    }

    /// <summary>
    /// حذف دائم لكل صور الوحدة
    /// </summary>
    public async Task<int> HardDeleteByUnitIdAsync(Guid unitId, CancellationToken cancellationToken = default)
    {
        var images = await _dbSet.IgnoreQueryFilters()
            .Where(pi => pi.UnitId == unitId)
            .ToListAsync(cancellationToken);
        if (images.Count == 0) return 0;
        _dbSet.RemoveRange(images);
        return await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<IEnumerable<PropertyImage>> GetByPropertyIdAsync(Guid propertyId, CancellationToken cancellationToken = default)
        => await GetImagesByPropertyAsync(propertyId, cancellationToken);

    public async Task<IEnumerable<PropertyImage>> GetImagesByPropertyAsync(Guid propertyId, CancellationToken cancellationToken = default)
        => await _dbSet
            .Where(pi => pi.PropertyId.HasValue && pi.PropertyId.Value == propertyId && !pi.IsDeleted)
            .OrderBy(pi => pi.DisplayOrder)
            .ThenBy(pi => pi.CreatedAt)
            .ToListAsync(cancellationToken);

    public async Task<IEnumerable<PropertyImage>> GetImagesByUnitAsync(Guid unitId, CancellationToken cancellationToken = default)
        => await _dbSet
            .Where(pi => pi.UnitId.HasValue && pi.UnitId.Value == unitId && !pi.IsDeleted)
            .OrderBy(pi => pi.DisplayOrder)
            .ThenBy(pi => pi.CreatedAt)
            .ToListAsync(cancellationToken);

    public async Task<IEnumerable<PropertyImage>> GetImagesBySectionAsync(Guid sectionId, CancellationToken cancellationToken = default)
        => await _dbSet
            .Where(pi => pi.SectionId.HasValue && pi.SectionId.Value == sectionId && !pi.IsDeleted)
            .OrderBy(pi => pi.DisplayOrder)
            .ThenBy(pi => pi.CreatedAt)
            .ToListAsync(cancellationToken);

    public async Task<IEnumerable<PropertyImage>> GetImagesByPropertyInSectionAsync(Guid propertyInSectionId, CancellationToken cancellationToken = default)
        => await _dbSet
            .Where(pi => pi.PropertyInSectionId.HasValue && pi.PropertyInSectionId.Value == propertyInSectionId && !pi.IsDeleted)
            .OrderBy(pi => pi.DisplayOrder)
            .ThenBy(pi => pi.CreatedAt)
            .ToListAsync(cancellationToken);

    public async Task<IEnumerable<PropertyImage>> GetImagesByUnitInSectionAsync(Guid unitInSectionId, CancellationToken cancellationToken = default)
        => await _dbSet
            .Where(pi => pi.UnitInSectionId.HasValue && pi.UnitInSectionId.Value == unitInSectionId && !pi.IsDeleted)
            .OrderBy(pi => pi.DisplayOrder)
            .ThenBy(pi => pi.CreatedAt)
            .ToListAsync(cancellationToken);

    public async Task<IEnumerable<PropertyImage>> GetImagesByCityAsync(string cityName, CancellationToken cancellationToken = default)
        => await _dbSet
            .Where(pi => pi.CityName != null && pi.CityName == cityName && !pi.IsDeleted)
            .OrderBy(pi => pi.DisplayOrder)
            .ThenBy(pi => pi.CreatedAt)
            .ToListAsync(cancellationToken);

    public async Task<PropertyImage?> GetMainImageByPropertyAsync(Guid propertyId, CancellationToken cancellationToken = default)
        => await _dbSet
            .FirstOrDefaultAsync(pi => pi.PropertyId == propertyId && pi.IsMainImage && !pi.IsDeleted, cancellationToken);

    public async Task<PropertyImage?> GetMainImageByUnitAsync(Guid unitId, CancellationToken cancellationToken = default)
        => await _dbSet
            .FirstOrDefaultAsync(pi => pi.UnitId == unitId && pi.IsMainImage && !pi.IsDeleted, cancellationToken);

    public async Task<PropertyImage?> GetMainImageByCityAsync(string cityName, CancellationToken cancellationToken = default)
        => await _dbSet
            .FirstOrDefaultAsync(pi => pi.CityName == cityName && pi.IsMainImage && !pi.IsDeleted, cancellationToken);

    public async Task<bool> AssignImageToPropertyAsync(Guid imageId, Guid propertyId, CancellationToken cancellationToken = default)
    {
        var image = await GetByIdAsync(imageId, cancellationToken);
        if (image == null) return false;

        image.PropertyId = propertyId;
        image.UnitId = null; // Remove from unit if assigned
        image.UpdatedAt = DateTime.UtcNow;

        _dbSet.Update(image);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> AssignImageToUnitAsync(Guid imageId, Guid unitId, CancellationToken cancellationToken = default)
    {
        var image = await GetByIdAsync(imageId, cancellationToken);
        if (image == null) return false;

        image.UnitId = unitId;
        image.PropertyId = null; // Remove from property if assigned
        image.UpdatedAt = DateTime.UtcNow;

        _dbSet.Update(image);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> UnassignImageAsync(Guid imageId, CancellationToken cancellationToken = default)
    {
        var image = await GetByIdAsync(imageId, cancellationToken);
        if (image == null) return false;

        image.PropertyId = null;
        image.UnitId = null;
        image.UpdatedAt = DateTime.UtcNow;

        _dbSet.Update(image);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> UpdateMainImageStatusAsync(Guid imageId, bool isMain, CancellationToken cancellationToken = default)
    {
        var image = await GetByIdAsync(imageId, cancellationToken);
        if (image == null) return false;

        // If setting as main, remove main status from other images in the same property/unit
        if (isMain)
        {
            if (image.PropertyId.HasValue)
            {
                var otherMainImages = await _dbSet
                    .Where(pi => pi.PropertyId == image.PropertyId && pi.Id != imageId && (pi.IsMainImage || pi.IsMain))
                    .ToListAsync(cancellationToken);

                foreach (var otherImage in otherMainImages)
                {
                    otherImage.IsMainImage = false;
                    otherImage.IsMain = false;
                    otherImage.UpdatedAt = DateTime.UtcNow;
                }
            }

            if (image.UnitId.HasValue)
            {
                var otherMainImages = await _dbSet
                    .Where(pi => pi.UnitId == image.UnitId && pi.Id != imageId && (pi.IsMainImage || pi.IsMain))
                    .ToListAsync(cancellationToken);

                foreach (var otherImage in otherMainImages)
                {
                    otherImage.IsMainImage = false;
                    otherImage.IsMain = false;
                    otherImage.UpdatedAt = DateTime.UtcNow;
                }
            }

            if (!string.IsNullOrWhiteSpace(image.CityName))
            {
                var otherMainImages = await _dbSet
                    .Where(pi => pi.CityName == image.CityName && pi.Id != imageId && (pi.IsMainImage || pi.IsMain))
                    .ToListAsync(cancellationToken);

                foreach (var otherImage in otherMainImages)
                {
                    otherImage.IsMainImage = false;
                    otherImage.IsMain = false;
                    otherImage.UpdatedAt = DateTime.UtcNow;
                }
            }
        }

        image.IsMainImage = isMain;
        image.IsMain = isMain;
        image.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);

        // Also persist the main image reference into parent tables if columns exist
        try
        {
            if (image.PropertyId.HasValue)
            {
                // Try set FK column if present
                await _context.Database.ExecuteSqlRawAsync(
                    "UPDATE Properties SET ImageId = {0} WHERE PropertyId = {1}",
                    image.Id, image.PropertyId.Value);
                // Try set URL column if present (ignore if it doesn't exist)
                await _context.Database.ExecuteSqlRawAsync(
                    "BEGIN TRY UPDATE Properties SET MainImageUrl = {0} WHERE PropertyId = {1} END TRY BEGIN CATCH END",
                    image.Url, image.PropertyId.Value);
            }
            if (image.UnitId.HasValue)
            {
                await _context.Database.ExecuteSqlRawAsync(
                    "BEGIN TRY UPDATE Units SET ImageId = {0} WHERE UnitId = {1} END TRY BEGIN CATCH END",
                    image.Id, image.UnitId.Value);
                await _context.Database.ExecuteSqlRawAsync(
                    "BEGIN TRY UPDATE Units SET MainImageUrl = {0} WHERE UnitId = {1} END TRY BEGIN CATCH END",
                    image.Url, image.UnitId.Value);
            }
            if (!string.IsNullOrWhiteSpace(image.CityName))
            {
                await _context.Database.ExecuteSqlRawAsync(
                    "BEGIN TRY UPDATE Cities SET ImagesJson = ImagesJson WHERE Name = {0} END TRY BEGIN CATCH END",
                    image.CityName);
            }
        }
        catch
        {
            // Best-effort: if columns don't exist, ignore
        }
        return true;
    }

    public async Task<IEnumerable<PropertyImage>> GetImagesByCategoryAsync(ImageCategory category, CancellationToken cancellationToken = default)
        => await _dbSet
            .Where(pi => pi.Category == category && !pi.IsDeleted)
            .OrderBy(pi => pi.CreatedAt)
            .ToListAsync(cancellationToken);

    /// <inheritdoc />
    public async Task<IEnumerable<PropertyImage>> GetImagesByPathAsync(IEnumerable<string> paths, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Where(pi => paths.Contains(pi.Url))
            .ToListAsync(cancellationToken);
    }

    /// <summary>
    /// جلب صور حسب المفتاح المؤقت
    /// </summary>
    public async Task<IEnumerable<PropertyImage>> GetImagesByTempKeyAsync(string tempKey, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Where(pi => pi.TempKey == tempKey && !pi.IsDeleted)
            .OrderBy(pi => pi.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    /// <inheritdoc />
    public async Task<bool> UpdateDisplayOrdersAsync(IEnumerable<(Guid imageId, int displayOrder)> assignments, CancellationToken cancellationToken = default)
    {
        // Minimize round-trips and reduce lock time: load all once, then update
        var ids = assignments.Select(a => a.imageId).ToList();
        var images = await _dbSet
            .Where(pi => ids.Contains(pi.Id))
            .ToListAsync(cancellationToken);

        var orderLookup = assignments.ToDictionary(a => a.imageId, a => a.displayOrder);
        foreach (var img in images)
        {
            if (orderLookup.TryGetValue(img.Id, out var newOrder))
            {
                img.DisplayOrder = newOrder;
                img.UpdatedAt = DateTime.UtcNow;
            }
        }

        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }
}
