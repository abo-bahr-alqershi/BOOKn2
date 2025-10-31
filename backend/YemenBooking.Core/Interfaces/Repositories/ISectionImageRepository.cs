using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Core.Interfaces.Repositories;

public interface ISectionImageRepository : IRepository<SectionImage>
{
    Task<SectionImage> CreateAsync(SectionImage image, CancellationToken cancellationToken = default);
    Task<SectionImage?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<SectionImage> UpdateAsync(SectionImage image, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<SectionImage>> GetBySectionIdAsync(Guid sectionId, CancellationToken cancellationToken = default);
    Task<bool> UpdateDisplayOrdersAsync(IEnumerable<(Guid imageId, int displayOrder)> assignments, CancellationToken cancellationToken = default);
    Task<bool> UpdateMainImageStatusAsync(Guid imageId, bool isMain, CancellationToken cancellationToken = default);
    Task<IEnumerable<SectionImage>> GetByTempKeyAsync(string tempKey, CancellationToken cancellationToken = default);
}

