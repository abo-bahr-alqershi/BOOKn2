using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Properties.Commands.UploadImages;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم برفع الصور للمدراء
    /// Controller for uploading images by admins
    /// </summary>
    public class UploadImageController : BaseAdminController
    {
        public UploadImageController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// رفع صورة مع بيانات إضافية
        /// Upload an image with additional data
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> UploadImage([FromBody] UploadImageCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }
    }
} 