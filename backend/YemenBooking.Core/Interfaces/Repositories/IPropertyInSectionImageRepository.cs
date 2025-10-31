using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Core.Interfaces.Repositories;

public interface IPropertyInSectionImageRepository : IRepository<PropertyInSectionImage>
{
    Task<PropertyInSectionImage> CreateAsync(PropertyInSectionImage image, CancellationToken cancellationToken = default);
    Task<PropertyInSectionImage?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<PropertyInSectionImage> UpdateAsync(PropertyInSectionImage image, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<PropertyInSectionImage>> GetByPropertyInSectionIdAsync(Guid propertyInSectionId, CancellationToken cancellationToken = default);
    Task<bool> UpdateDisplayOrdersAsync(IEnumerable<(Guid imageId, int displayOrder)> assignments, CancellationToken cancellationToken = default);
    Task<bool> UpdateMainImageStatusAsync(Guid imageId, bool isMain, CancellationToken cancellationToken = default);
    Task<IEnumerable<PropertyInSectionImage>> GetByTempKeyAsync(string tempKey, CancellationToken cancellationToken = default);
}

