using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Favorites.Commands.ToFavorites;
using YemenBooking.Application.Features.Favorites.Commands.FromFavorites;
using YemenBooking.Application.Features.Favorites.Queries.GetUserFavorites;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Api.Controllers.Client
{
    /// <summary>
    /// كونترولر إدارة المفضلات للعملاء
    /// Client Favorites Management Controller
    /// </summary>
    public class FavoritesController : BaseClientController
    {
        public FavoritesController(IMediator mediator) : base(mediator)
        {
        }

        /// <summary>
        /// إضافة عقار للمفضلات
        /// Add property to favorites
        /// </summary>
        /// <param name="command">بيانات إضافة للمفضلات</param>
        /// <returns>نتيجة الإضافة</returns>
        [HttpPost]
        public async Task<ActionResult<ResultDto<AddToFavoritesResponse>>> AddToFavorites([FromBody] AddToFavoritesCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إزالة عقار من المفضلات
        /// Remove property from favorites
        /// </summary>
        /// <param name="command">بيانات الإزالة من المفضلات</param>
        /// <returns>نتيجة الإزالة</returns>
        [HttpDelete]
        public async Task<ActionResult<ResultDto<RemoveFromFavoritesResponse>>> RemoveFromFavorites([FromBody] RemoveFromFavoritesCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على قائمة مفضلات المستخدم
        /// Get user favorites list
        /// </summary>
        /// <param name="query">معايير البحث</param>
        /// <returns>قائمة المفضلات</returns>
        [HttpGet]
        public async Task<ActionResult<ResultDto<UserFavoritesResponse>>> GetUserFavorites([FromQuery] GetUserFavoritesQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
}
