using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Favorites.Commands.FromFavorites;

/// <summary>
/// أمر إزالة كيان من المفضلات
/// Command to remove property from favorites
/// </summary>
public class RemoveFromFavoritesCommand : IRequest<ResultDto<RemoveFromFavoritesResponse>>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// معرف الكيان
    /// </summary>
    public Guid PropertyId { get; set; }
}

/// <summary>
/// استجابة إزالة من المفضلات
/// </summary>
public class RemoveFromFavoritesResponse
{
    /// <summary>
    /// نجاح الإزالة
    /// </summary>
    public bool Success { get; set; }
    
    /// <summary>
    /// رسالة النتيجة
    /// </summary>
    public string Message { get; set; } = string.Empty;
}