using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.Queries.SearchAdvancedProperty;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Infrastructure.Persistence.Repositories
{
    /// <summary>
    /// واجهة مستودع البحث المتقدم عن الكيانات
    /// Defines methods for advanced property search queries
    /// </summary>
    public interface IAdvancedPropertySearchRepository
    {
        Task<IEnumerable<AdvancedPropertyDto>> SearchAsync(AdvancedPropertySearchQuery query, CancellationToken cancellationToken = default);
    }
} 