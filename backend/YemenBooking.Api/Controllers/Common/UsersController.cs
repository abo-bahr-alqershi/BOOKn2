using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Users.Commands.UpdateUser;
using YemenBooking.Application.Features.Users.Queries.GetCurrentUser;

namespace YemenBooking.Api.Controllers.Common
{
    /// <summary>
    /// متحكم ببيانات وإعدادات المستخدم العامة
    /// Controller for common user operations: current user, profile picture, and settings
    /// </summary>
    public class UsersController : BaseCommonController
    {
        public UsersController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// جلب بيانات المستخدم الحالي
        /// Get current user details
        /// </summary>
        [HttpGet("current")]
        [Authorize]
        public async Task<IActionResult> GetCurrentUser()
        {
            var query = new GetCurrentUserQuery();
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// تحديث صورة الملف الشخصي
        /// Update user profile picture
        /// </summary>
        [HttpPut("profile-picture")]
        public async Task<IActionResult> UpdateProfilePicture([FromBody] UpdateUserProfilePictureCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث إعدادات المستخدم بصيغة JSON
        /// Update user settings JSON
        /// </summary>
        [HttpPut("settings")]
        public async Task<IActionResult> UpdateUserSettings([FromBody] UpdateUserSettingsCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }
    }
} 