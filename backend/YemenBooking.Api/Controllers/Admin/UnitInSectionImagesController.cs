using System;
using System.IO;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Sections.Commands.UpdateUnit;
using YemenBooking.Application.Features.Properties.Commands.UploadImages;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Sections.Commands.ManageImages;
using YemenBooking.Application.Features.Properties.Commands.ManageImages;
using YemenBooking.Application.Features.Sections.Commands.DeleteUnit;
using YemenBooking.Application.Features.Sections.Queries.GetImages;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// إدارة صور "وحدة في قسم"
    /// </summary>
    [Route("api/admin/unit-in-section-images")]
    [ApiController]
    [Authorize]
    public class UnitInSectionImagesController : BaseAdminController
    {
        public UnitInSectionImagesController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// رفع صورة لوحدة في قسم
        /// </summary>
        [HttpPost("upload")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Upload(
            [FromForm] IFormFile? file,
            [FromForm] IFormFile? videoThumbnail,
            [FromForm] string? unitInSectionId,
            [FromForm] string? tempKey,
            [FromForm] string? category,
            [FromForm] string? alt,
            [FromForm] bool? isPrimary,
            [FromForm] int? order,
            [FromForm] string? tags)
        {
            // Log incoming request
            Console.WriteLine($"[UnitImage] Upload called at {DateTime.Now:HH:mm:ss.fff}");
            Console.WriteLine($"[UnitImage] unitInSectionId: {unitInSectionId}, tempKey: {tempKey}");
            Console.WriteLine($"[UnitImage] file: {file?.FileName}, size: {file?.Length}");
            Console.WriteLine("[UnitImage] STEP 1: Enter action");
            
            // Fallback: if model binding didn't populate files, read from Request.Form manually
            if ((file == null || file.Length == 0) && Request.HasFormContentType)
            {
                try
                {
                    Console.WriteLine("[UnitImage] STEP 1.1: Attempting Request.ReadFormAsync fallback");
                    var form = await Request.ReadFormAsync();
                    file = form.Files["file"] ?? file;
                    videoThumbnail = form.Files["videoThumbnail"] ?? videoThumbnail;
                    unitInSectionId = string.IsNullOrWhiteSpace(unitInSectionId) ? form["unitInSectionId"].ToString() : unitInSectionId;
                    tempKey = string.IsNullOrWhiteSpace(tempKey) ? form["tempKey"].ToString() : tempKey;
                    category = string.IsNullOrWhiteSpace(category) ? form["category"].ToString() : category;
                    alt = string.IsNullOrWhiteSpace(alt) ? form["alt"].ToString() : alt;
                    if (!isPrimary.HasValue && bool.TryParse(form["isPrimary"], out var ip)) isPrimary = ip;
                    if (!order.HasValue && int.TryParse(form["order"], out var ord)) order = ord;
                    if (string.IsNullOrWhiteSpace(tags)) tags = form["tags"].ToString();
                    Console.WriteLine($"[UnitImage] STEP 1.2: Fallback file={(file!=null ? file.FileName: "null")} size={file?.Length}");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[UnitImage] Fallback form read error: {ex}");
                }
            }

            if (file == null || file.Length == 0)
                return BadRequest(new { success = false, message = "file is required" });

            // Parse UnitInSectionId manually to avoid automatic 400 from model binder
            Guid? parsedUnitInSectionId = null;
            if (!string.IsNullOrWhiteSpace(unitInSectionId) && Guid.TryParse(unitInSectionId, out var uid))
            {
                parsedUnitInSectionId = uid;
            }

            if (parsedUnitInSectionId == null && string.IsNullOrWhiteSpace(tempKey))
            {
                return BadRequest(new { success = false, message = "Either unitInSectionId (GUID) or tempKey is required" });
            }
            Console.WriteLine("[UnitImage] STEP 2: Before file.CopyToAsync");
            using var ms = new MemoryStream();
            try
            {
                await file.CopyToAsync(ms);
                Console.WriteLine($"[UnitImage] STEP 3: After file.CopyToAsync, bytes={ms.Length}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[UnitImage] ERROR copying file: {ex}");
                return StatusCode(500, new { success = false, message = "Failed to read uploaded file" });
            }

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

            var cmd = new UploadUnitInSectionImageCommand
            {
                UnitInSectionId = parsedUnitInSectionId,
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

            Console.WriteLine("[UnitImage] STEP 4: Before mediator.Send");
            var result = await _mediator.Send(cmd);
            Console.WriteLine($"[UnitImage] STEP 5: After mediator.Send, success={result.Success}");
            return Ok(new { success = result.Success, message = result.Message, data = result.Data });
        }

        /// <summary>
        /// الحصول على صور وحدة في قسم
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Get(
            [FromQuery] string? unitInSectionId,
            [FromQuery] string? tempKey,
            [FromQuery] string? sortBy = "order",
            [FromQuery] string? sortOrder = "asc",
            [FromQuery] int? page = 1,
            [FromQuery] int? limit = 50)
        {
            Guid? parsedId = null;
            if (!string.IsNullOrWhiteSpace(unitInSectionId) && Guid.TryParse(unitInSectionId, out var id))
            {
                parsedId = id;
            }

            var q = new GetUnitInSectionImagesQuery
            {
                UnitInSectionId = parsedId,
                TempKey = string.IsNullOrWhiteSpace(tempKey) ? null : tempKey,
                SortBy = sortBy,
                SortOrder = sortOrder,
                Page = page ?? 1,
                Limit = limit ?? 50
            };

            var result = await _mediator.Send(q);
            if (!result.Success)
                return BadRequest(new { success = false, message = result.Message });

            return Ok(new
            {
                success = true,
                images = result.Data,
                items = result.Data // للتوافقية
            });
        }

        /// <summary>
        /// تحديث بيانات صورة
        /// </summary>
        [HttpPut("{imageId}")]
        public async Task<IActionResult> Update(Guid imageId, [FromBody] UpdateUnitInSectionImageCommand command)
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
            var result = await _mediator.Send(new DeleteUnitInSectionImageCommand
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
                .Select((id, idx) => new ImageOrderAssignment
                {
                    ImageId = Guid.Parse(id),
                    DisplayOrder = idx + 1
                })
                .ToList();

            var result = await _mediator.Send(new ReorderUnitInSectionImagesCommand
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
            var result = await _mediator.Send(new UpdateUnitInSectionImageCommand
            {
                ImageId = imageId,
                IsPrimary = true,
                UnitInSectionId = request?.UnitInSectionId,
                TempKey = request?.TempKey
            });

            if (!result.Success)
                return BadRequest(new { success = false, message = result.Message });

            return NoContent();
        }

        public class ReorderImagesRequest
        {
            public List<string> ImageIds { get; set; } = new();
            public Guid? UnitInSectionId { get; set; }
            public string? TempKey { get; set; }
        }

        public class SetPrimaryRequest
        {
            public Guid? UnitInSectionId { get; set; }
            public string? TempKey { get; set; }
        }
    }
}

