using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.GetPrivacyPolicy;

/// <summary>
/// استعلام الحصول على سياسة الخصوصية
/// Query to get privacy policy
/// </summary>
public class GetPrivacyPolicyQuery : IRequest<ResultDto<LegalDocumentDto>>
{
    /// <summary>
    /// اللغة المطلوبة
    /// </summary>
    public string Language { get; set; } = "ar";
}

// LegalDocumentDto تم تعريفه مسبقًا