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
    public class LegalDocumentRepository : BaseRepository<LegalDocument>, ILegalDocumentRepository
    {
        public LegalDocumentRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<LegalDocument?> GetDocumentAsync(Guid id)
            => await _dbSet.FindAsync(id);

        public async Task<List<LegalDocument>> GetAllDocumentsAsync()
            => await _dbSet.ToListAsync();

        public async Task<LegalDocument> CreateDocumentAsync(LegalDocument document)
        {
            await _dbSet.AddAsync(document);
            await _context.SaveChangesAsync();
            return document;
        }

        public async Task<bool> UpdateDocumentAsync(LegalDocument document)
        {
            _dbSet.Update(document);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteDocumentAsync(Guid id)
        {
            var document = await GetDocumentAsync(id);
            if (document != null)
            {
                _dbSet.Remove(document);
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }

        public Task<LegalDocument?> GetByTypeAndLanguageAsync(LegalDocumentType type, string language, CancellationToken cancellationToken = default)
        {
            throw new NotImplementedException();
        }

        public Task<IEnumerable<LegalDocument>> GetByTypeAsync(LegalDocumentType type, CancellationToken cancellationToken = default)
        {
            throw new NotImplementedException();
        }

        Task<LegalDocument> ILegalDocumentRepository.UpdateAsync(LegalDocument document, CancellationToken cancellationToken)
        {
            throw new NotImplementedException();
        }

        Task<bool> ILegalDocumentRepository.DeleteAsync(Guid id, CancellationToken cancellationToken)
        {
            throw new NotImplementedException();
        }
    }
}
