using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common;
using System;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.GetTermsAndConditions;

/// <summary>
/// استعلام الحصول على الشروط والأحكام
/// Query to get terms and conditions
/// </summary>
public class GetTermsAndConditionsQuery : IRequest<ResultDto<LegalDocumentDto>>
{
    /// <summary>
    /// اللغة المطلوبة
    /// </summary>
    public string Language { get; set; } = "ar";
}