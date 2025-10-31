using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Bookings.Commands.CreateBooking;
using YemenBooking.Application.Features.Bookings.Commands.CancelBooking;
using YemenBooking.Application.Features.Bookings.Commands.AddServices;
using YemenBooking.Application.Features.Bookings.Queries.GetUserBookings;
using YemenBooking.Application.Features.Bookings.Queries.GetBookingDetails;
using YemenBooking.Application.Features.Bookings.Queries.GetUserBookingSummarySummary;
using YemenBooking.Application.Common.Models;
using BookingDto = YemenBooking.Application.Features.Bookings.Queries.GetUserBookings.BookingDto;
using BookingDetailsDto = YemenBooking.Application.Features.Bookings.DTOs.BookingDetailsDto;

namespace YemenBooking.Api.Controllers.Client
{
    /// <summary>
    /// كونترولر إدارة الحجوزات للعملاء
    /// Client Booking Management Controller
    /// </summary>
    public class BookingController : BaseClientController
    {
        public BookingController(IMediator mediator) : base(mediator)
        {
        }

        /// <summary>
        /// إنشاء حجز جديد
        /// Create new booking
        /// </summary>
        /// <param name="command">بيانات الحجز</param>
        /// <returns>تفاصيل الحجز الجديد</returns>
        [HttpPost]
        public async Task<ActionResult<ResultDto<CreateBookingResponse>>> CreateBooking([FromBody] CreateBookingCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إلغاء حجز موجود
        /// Cancel existing booking
        /// </summary>
        /// <param name="command">بيانات إلغاء الحجز</param>
        /// <returns>نتيجة إلغاء الحجز</returns>
        [HttpPost("cancel")]
        public async Task<ActionResult<ResultDto<bool>>> CancelBooking([FromBody] CancelBookingCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إضافة خدمة للحجز
        /// Add service to booking
        /// </summary>
        /// <param name="command">بيانات الخدمة المراد إضافتها</param>
        /// <returns>نتيجة إضافة الخدمة</returns>
        [HttpPost("add-service")]
        public async Task<ActionResult<ResultDto<AddServicesToBookingResponse>>> AddServiceToBooking([FromBody] AddServicesToBookingCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على قائمة حجوزات المستخدم
        /// Get user bookings list
        /// </summary>
        /// <param name="query">معايير البحث والفلترة</param>
        /// <returns>قائمة حجوزات المستخدم</returns>
        [HttpGet]
        public async Task<ActionResult<ResultDto<PaginatedResult<BookingDto>>>> GetUserBookings([FromQuery] GetUserBookingsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على تفاصيل حجز محدد
        /// Get specific booking details
        /// </summary>
        /// <param name="id">معرف الحجز</param>
        /// <param name="userId">معرف المستخدم</param>
        /// <returns>تفاصيل الحجز</returns>
        [HttpGet("{id}")]
    public async Task<ActionResult<ResultDto<BookingDetailsDto>>> GetBookingDetails(Guid id, [FromQuery] Guid userId)
        {
            var query = new GetBookingDetailsQuery { BookingId = id, UserId = userId };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على ملخص حجوزات المستخدم
        /// Get user booking summary
        /// </summary>
        /// <param name="userId">معرف المستخدم</param>
        /// <param name="year">السنة</param>
        /// <returns>ملخص الحجوزات</returns>
        [HttpGet("summary/{userId}")]
        public async Task<ActionResult<ResultDto<UserBookingSummaryDto>>> GetUserBookingSummary(Guid userId, [FromQuery] int? year)
        {
            var query = new GetUserBookingSummaryQuery { UserId = userId, Year = year };
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
}
