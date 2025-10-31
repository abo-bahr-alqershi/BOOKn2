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

namespace YemenBooking.Infrastructure.Repositories
{
    public class FAQRepository : BaseRepository<FAQ>, IFAQRepository
    {
        public FAQRepository(YemenBookingDbContext context) : base(context) { }

        public Task<IEnumerable<FAQ>> GetActiveFAQsAsync(string language = "ar", string? category = null, CancellationToken cancellationToken = default)
        {
            throw new NotImplementedException();
        }

        public Task<Dictionary<string, List<FAQ>>> GetFAQsGroupedByCategoryAsync(string language = "ar", CancellationToken cancellationToken = default)
        {
            throw new NotImplementedException();
        }

        public Task<bool> IncrementViewCountAsync(Guid id, CancellationToken cancellationToken = default)
        {
            throw new NotImplementedException();
        }

        public Task<IEnumerable<FAQ>> SearchFAQsAsync(string searchTerm, string language = "ar", CancellationToken cancellationToken = default)
        {
            throw new NotImplementedException();
        }

        Task<bool> IFAQRepository.DeleteAsync(Guid id, CancellationToken cancellationToken)
        {
            throw new NotImplementedException();
        }

        Task<FAQ> IFAQRepository.UpdateAsync(FAQ faq, CancellationToken cancellationToken)
        {
            throw new NotImplementedException();
        }
    }
}
