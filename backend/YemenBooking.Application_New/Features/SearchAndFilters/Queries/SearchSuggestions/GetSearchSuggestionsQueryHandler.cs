using MediatR;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
// using YemenBooking.Application.Features.Search; // غير موجود
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.SearchSuggestions
{
    /// <summary>
    /// معالج استعلام اقتراحات البحث بناءً على سجل البحث.
    /// </summary>
    public class GetSearchSuggestionsQueryHandler : IRequestHandler<GetSearchSuggestionsQuery, ResultDto<List<string>>>
    {
        private readonly ISearchLogRepository _searchLogRepository;
        private readonly ILogger<GetSearchSuggestionsQueryHandler> _logger;

        public GetSearchSuggestionsQueryHandler(ISearchLogRepository searchLogRepository, ILogger<GetSearchSuggestionsQueryHandler> logger)
        {
            _searchLogRepository = searchLogRepository;
            _logger = logger;
        }

        public async Task<ResultDto<List<string>>> Handle(GetSearchSuggestionsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("Fetching search suggestions for query: {Query}", request.Query);

            // Filter logs containing the search term in JSON criteria
            var logs = await _searchLogRepository.GetQueryable()
                .Where(x => EF.Functions.Like(x.CriteriaJson, $"%\"SearchTerm\":\"{request.Query}%\""))
                .OrderByDescending(x => x.CreatedAt)
                .Take(request.Limit * 5)
                .ToListAsync(cancellationToken);

            // Parse JSON and extract SearchTerm values
            var suggestions = logs
                .Select(x =>
                {
                    try
                    {
                        using var doc = JsonDocument.Parse(x.CriteriaJson);
                        if (doc.RootElement.TryGetProperty("SearchTerm", out var term))
                        {
                            return term.GetString() ?? string.Empty;
                        }
                    }
                    catch (JsonException)
                    {
                        // ignore parse errors
                    }
                    return string.Empty;
                })
                .Where(s => !string.IsNullOrEmpty(s))
                .Distinct()
                .Take(request.Limit)
                .ToList();

            return ResultDto<List<string>>.Ok(suggestions, "Search suggestions fetched successfully");
        }
    }
}