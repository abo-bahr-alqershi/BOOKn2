using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Amenities.Commands.ManageAmenities;
using YemenBooking.Application.Features.Amenities.Commands.AssignAmenities;
using YemenBooking.Application.Features.Amenities.Queries.GetAllAmenities;
using YemenBooking.Application.Features.Amenities.Queries.GetAmenityById;
using YemenBooking.Application.Features.Amenities.Queries.GetAmenityStats;
using YemenBooking.Application.Features.Amenities.Queries.GetPopularAmenities;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بإدارة المرافق للمدراء
    /// Controller for managing amenities by admins
    /// </summary>
    public class AmenitiesController : BaseAdminController
    {
        public AmenitiesController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// إنشاء مرفق جديد
        /// Create a new amenity
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateAmenity([FromBody] CreateAmenityCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث مرفق موجود
        /// Update an existing amenity
        /// </summary>
        [HttpPut("{amenityId}")]
        public async Task<IActionResult> UpdateAmenity(Guid amenityId, [FromBody] UpdateAmenityCommand command)
        {
            command.AmenityId = amenityId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// حذف مرفق
        /// Delete an amenity
        /// </summary>
        [HttpDelete("{amenityId}")]
        public async Task<IActionResult> DeleteAmenity(Guid amenityId)
        {
            var command = new DeleteAmenityCommand { AmenityId = amenityId };
            var result = await _mediator.Send(command);
            // If failed due to reference checks, return 409 with reason
            if (!result.IsSuccess && (result.Message?.Contains("لا يمكن حذف المرفق") == true))
            {
                return Conflict(ResultDto.Failure(result.Message, errorCode: "AMENITY_DELETE_CONFLICT"));
            }
            return Ok(result);
        }

        /// <summary>
        /// جلب جميع المرافق مع الصفحات
        /// Get all amenities with pagination
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAllAmenities([FromQuery] GetAllAmenitiesQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب مرفق حسب المعرف
        /// Get amenity by id
        /// </summary>
        [HttpGet("{amenityId}")]
        public async Task<IActionResult> GetAmenityById(Guid amenityId)
        {
            var result = await _mediator.Send(new GetAmenityByIdQuery { AmenityId = amenityId });
            return Ok(ResultDto<AmenityDto>.Ok(result));
        }

        /// <summary>
        /// إحصائيات المرافق
        /// Amenities stats
        /// </summary>
        [HttpGet("stats")]
        public async Task<IActionResult> GetAmenityStats()
        {
            var result = await _mediator.Send(new GetAmenityStatsQuery());
            return Ok(ResultDto<AmenityStatsDto>.Ok(result));
        }

        /// <summary>
        /// المرافق الشائعة
        /// Popular amenities
        /// </summary>
        [HttpGet("popular")]
        public async Task<IActionResult> GetPopularAmenities([FromQuery] int limit = 10)
        {
            var result = await _mediator.Send(new GetPopularAmenitiesQuery { Limit = limit });
            return Ok(ResultDto<List<AmenityDto>>.Ok(result));
        }

        /// <summary>
        /// تبديل حالة المرفق (تفعيل/تعطيل)
        /// Toggle amenity status
        /// </summary>
        [HttpPost("{amenityId}/toggle-status")]
        public async Task<IActionResult> ToggleAmenityStatus(Guid amenityId)
        {
            var cmd = new ToggleAmenityStatusCommand { AmenityId = amenityId };
            var result = await _mediator.Send(cmd);
            return Ok(result);
        }

        /// <summary>
        /// إسناد مرفق لكيان
        /// Assign an amenity to a property
        /// </summary>
        [HttpPost("{amenityId}/assign/property/{propertyId}")]
        public async Task<IActionResult> AssignAmenityToProperty(Guid amenityId, Guid propertyId, [FromBody] AssignAmenityToPropertyCommand command)
        {
            command.AmenityId = amenityId;
            command.PropertyId = propertyId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إلغاء إسناد مرفق من عقار
        /// Unassign an amenity from a property
        /// </summary>
        [HttpDelete("{amenityId}/assign/property/{propertyId}")]
        public async Task<IActionResult> UnassignAmenityFromProperty(Guid amenityId, Guid propertyId)
        {
            var cmd = new UnassignAmenityFromPropertyCommand
            {
                AmenityId = amenityId,
                PropertyId = propertyId
            };
            var result = await _mediator.Send(cmd);
            if (!result.IsSuccess)
                return Conflict(ResultDto.Failure(result.Message ?? "تعذر إلغاء الإسناد"));
            return Ok(result);
        }

        /// <summary>
        /// تخصيص مرفق لنوع الكيان
        /// Assign an amenity to a property type
        /// </summary>
        [HttpPost("{amenityId}/assign/property-type/{propertyTypeId}")]
        public async Task<IActionResult> AssignAmenityToPropertyType(Guid amenityId, Guid propertyTypeId, [FromBody] AssignAmenityToPropertyTypeCommand command)
        {
            command.AmenityId = amenityId;
            command.PropertyTypeId = propertyTypeId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }
    }
} 