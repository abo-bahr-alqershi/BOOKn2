using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.GetFAQs;

/// <summary>
/// استعلام الحصول على الأسئلة الشائعة
/// Query to get frequently asked questions
/// </summary>
public class GetFAQsQuery : IRequest<ResultDto<List<FAQCategoryDto>>>
{
    /// <summary>
    /// اللغة المطلوبة
    /// </summary>
    public string Language { get; set; } = "ar";
    
    /// <summary>
    /// فئة معينة (اختياري)
    /// </summary>
    public string? Category { get; set; }
}

/// <summary>
/// بيانات فئة الأسئلة الشائعة
/// </summary>
public class FAQCategoryDto
{
    /// <summary>
    /// اسم الفئة
    /// </summary>
    public string CategoryName { get; set; } = string.Empty;
    
    /// <summary>
    /// أيقونة الفئة
    /// </summary>
    public string? CategoryIcon { get; set; }
    
    /// <summary>
    /// قائمة الأسئلة في هذه الفئة
    /// </summary>
    public List<FAQItemDto> Questions { get; set; } = new();
}

/// <summary>
/// بيانات السؤال الشائع
/// </summary>
public class FAQItemDto
{
    /// <summary>
    /// معرف السؤال
    /// </summary>
    public Guid Id { get; set; }
    
    /// <summary>
    /// السؤال
    /// </summary>
    public string Question { get; set; } = string.Empty;
    
    /// <summary>
    /// الإجابة
    /// </summary>
    public string Answer { get; set; } = string.Empty;
    
    /// <summary>
    /// ترتيب العرض
    /// </summary>
    public int DisplayOrder { get; set; }
    
    /// <summary>
    /// هل كانت الإجابة مفيدة (للإحصائيات)
    /// </summary>
    public int HelpfulCount { get; set; }
    
    /// <summary>
    /// هل كانت الإجابة غير مفيدة (للإحصائيات)
    /// </summary>
    public int NotHelpfulCount { get; set; }
}