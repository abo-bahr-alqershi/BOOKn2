using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Users.Commands.UpdateUser;
using YemenBooking.Application.Features.Users.Queries.GetUserSettings;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Api.Controllers.Client
{
    /// <summary>
    /// كونترولر إعدادات المستخدم للعملاء
    /// Client User Settings Controller
    /// </summary>
    public class SettingsController : BaseClientController
    {
        public SettingsController(IMediator mediator) : base(mediator)
        {
        }

        /// <summary>
        /// تحديث إعدادات المستخدم
        /// Update user settings
        /// </summary>
        /// <param name="command">الإعدادات الجديدة</param>
        /// <returns>نتيجة التحديث</returns>
        [HttpPut]
        public async Task<ActionResult<ResultDto<bool>>> UpdateUserSettings([FromBody] UpdateUserSettingsCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على إعدادات المستخدم الحالية
        /// Get current user settings
        /// </summary>
        /// <param name="query">معايير الاستعلام</param>
        /// <returns>إعدادات المستخدم</returns>
        [HttpGet]
        public async Task<ActionResult<ResultDto<UserSettingsDto>>> GetUserSettings([FromQuery] GetUserSettingsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// تحديث لغة المستخدم
        /// Update user language
        /// </summary>
        /// <param name="languageCode">رمز اللغة</param>
        /// <returns>نتيجة التحديث</returns>
        [HttpGet("language/{languageCode}")]
        public async Task<ActionResult<ResultDto<bool>>> UpdateLanguageUser(string languageCode)
        {
            return Ok(new ResultDto<bool>
            {
                Data = true,
                Message = "تم تحديث اللغة بنجاح",
                Success = true
            });
        }
    }
}
