using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.SearchSuggestions
{
    /// <summary>
    /// استعلام الحصول على اقتراحات البحث بناءً على سجل البحث السابق.
    /// </summary>
    public class GetSearchSuggestionsQuery : IRequest<ResultDto<List<string>>>
    {
        /// <summary>
        /// مصطلح البحث الحالي لاقتراح التكملة
        /// </summary>
        public string Query { get; set; } = string.Empty;

        /// <summary>
        /// الحد الأقصى لعدد الاقتراحات المطلوبة
        /// </summary>
        public int Limit { get; set; } = 10;
    }
}