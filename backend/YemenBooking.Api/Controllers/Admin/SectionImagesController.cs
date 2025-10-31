using System;
using System.IO;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Sections.Commands.ManageImages;
using YemenBooking.Application.Features.Properties.Commands.UploadImages;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Properties.Commands.ManageImages;
using YemenBooking.Application.Features.Sections.Queries.GetImages;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// إدارة صور الأقسام
    /// </summary>
    [Route("api/admin/section-images")]
    [ApiController]
    [Authorize]
    public class SectionImagesController : BaseAdminController
    {
        public SectionImagesController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// رفع صورة لقسم
        /// </summary>
        [HttpPost("upload")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Upload(
            IFormFile file, 
            IFormFile? videoThumbnail,
            [FromForm] Guid? sectionId,
            [FromForm] string? tempKey,
            [FromForm] string? category, 
            [FromForm] string? alt, 
            [FromForm] bool? isPrimary, 
            [FromForm] int? order, 
            [FromForm] string? tags)
        {
            if (file == null || file.Length == 0) 
                return BadRequest(new { success = false, message = "file is required" });

            using var ms = new MemoryStream();
            await file.CopyToAsync(ms);
            
            FileUploadRequest? poster = null;
            if (videoThumbnail != null)
            {
                using var ps = new MemoryStream();
                await videoThumbnail.CopyToAsync(ps);
                poster = new FileUploadRequest 
                { 
                    FileName = videoThumbnail.FileName, 
                    FileContent = ps.ToArray(), 
                    ContentType = videoThumbnail.ContentType 
                };
            }

            var cmd = new UploadSectionImageCommand
            {
                SectionId = sectionId,
                TempKey = string.IsNullOrWhiteSpace(tempKey) ? null : tempKey,
                File = new FileUploadRequest 
                { 
                    FileName = file.FileName, 
                    FileContent = ms.ToArray(), 
                    ContentType = file.ContentType 
                },
                VideoThumbnail = poster,
                Name = Path.GetFileNameWithoutExtension(file.FileName),
                Extension = Path.GetExtension(file.FileName),
                Category = Enum.TryParse<ImageCategory>(category, true, out var cat) ? cat : ImageCategory.Gallery,
                Alt = alt,
                IsPrimary = isPrimary ?? false,
                Order = order,
                Tags = string.IsNullOrWhiteSpace(tags) ? null : new System.Collections.Generic.List<string>(tags.Split(new[] { ',', ' ' }, StringSplitOptions.RemoveEmptyEntries))
            };

            var result = await _mediator.Send(cmd);
            return Ok(new { success = result.Success, message = result.Message, data = result.Data });
        }

        /// <summary>
        /// الحصول على صور قسم
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Get(
            [FromQuery] Guid? sectionId,
            [FromQuery] string? tempKey,
            [FromQuery] string? sortBy = "order",
            [FromQuery] string? sortOrder = "asc",
            [FromQuery] int? page = 1, 
            [FromQuery] int? limit = 50)
        {
            var q = new GetSectionImagesQuery 
            { 
                SectionId = sectionId,
                TempKey = tempKey,
                SortBy = sortBy,
                SortOrder = sortOrder,
                Page = page ?? 1, 
                Limit = limit ?? 50 
            };

            var result = await _mediator.Send(q);
            if (!result.Success) 
                return BadRequest(new { success = false, message = result.Message });

            return Ok(new { 
                success = true, 
                images = result.Data,
                items = result.Data // للتوافقية
            });
        }

        /// <summary>
        /// تحديث بيانات صورة
        /// </summary>
        [HttpPut("{imageId}")]
        public async Task<IActionResult> Update(Guid imageId, [FromBody] UpdateSectionImageCommand command)
        {
            command.ImageId = imageId;
            var result = await _mediator.Send(command);
            return Ok(new { success = result.Success, message = result.Message, data = result.Data });
        }

        /// <summary>
        /// حذف صورة
        /// </summary>
        [HttpDelete("{imageId}")]
        public async Task<IActionResult> Delete(Guid imageId, [FromQuery] bool permanent = false)
        {
            var result = await _mediator.Send(new DeleteSectionImageCommand 
            { 
                ImageId = imageId, 
                Permanent = permanent 
            });
            
            return Ok(new { success = result.Success, message = result.Message });
        }

        /// <summary>
        /// إعادة ترتيب الصور
        /// </summary>
        [HttpPost("reorder")]
        public async Task<IActionResult> Reorder([FromBody] ReorderImagesRequest request)
        {
            var assignments = request.ImageIds
                .Select((id, index) => new ImageOrderAssignment 
                { 
                    ImageId = Guid.Parse(id), 
                    DisplayOrder = index + 1 
                })
                .ToList();

            var result = await _mediator.Send(new ReorderSectionImagesCommand 
            { 
                Assignments = assignments 
            });

            if (!result.Success) 
                return BadRequest(new { success = false, message = result.Message });

            return NoContent();
        }

        /// <summary>
        /// تعيين صورة كرئيسية
        /// </summary>
        [HttpPost("{imageId}/set-primary")]
        public async Task<IActionResult> SetPrimary(
            Guid imageId,
            [FromBody] SetPrimaryRequest? request = null)
        {
            var result = await _mediator.Send(new UpdateSectionImageCommand 
            { 
                ImageId = imageId, 
                IsPrimary = true,
                SectionId = request?.SectionId,
                TempKey = request?.TempKey
            });

            if (!result.Success) 
                return BadRequest(new { success = false, message = result.Message });

            return NoContent();
        }

        public class ReorderImagesRequest
        {
            public List<string> ImageIds { get; set; } = new();
            public Guid? SectionId { get; set; }
            public string? TempKey { get; set; }
        }

        public class SetPrimaryRequest
        {
            public Guid? SectionId { get; set; }
            public string? TempKey { get; set; }
        }
    }
}