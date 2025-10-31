using System;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Bookings.Commands.CancelBooking;
using YemenBooking.Application.Features.Bookings.Commands.UpdateBooking;
using YemenBooking.Application.Features.Bookings.Commands.ConfirmBooking;
using YemenBooking.Application.Features.Bookings.Commands.CheckInOut;
using YemenBooking.Application.Features.Payments.Commands.RegisterBookingPayment;
using YemenBooking.Application.Features.Bookings.Queries.GetBookingById;
using YemenBooking.Application.Features.Bookings.Queries.GetBookingsByProperty;
using YemenBooking.Application.Features.Bookings.Queries.GetBookingsByStatus;
using YemenBooking.Application.Features.Bookings.Queries.GetBookingsByUnit;
using YemenBooking.Application.Features.Bookings.Queries.GetBookingsByUser;
using YemenBooking.Application.Features.Bookings.Queries.GetBookingServices;
using YemenBooking.Application.Features.Bookings.Queries.GetBookingsByDateRange;
using YemenBooking.Application.Features.Analytics.Queries.BookingAnalytics;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بإدارة الحجوزات للمدراء
    /// Controller for booking management by admins
    [ApiController]
    [Route("api/admin/[controller]")]
    [Authorize(Roles = "Admin,Owner,Staff")]
    public class BookingsController : ControllerBase
    {
        private readonly IMediator _mediator;

        public BookingsController(IMediator mediator)
        {
            _mediator = mediator;
        }

        /// <summary>
        /// إلغاء حجز
        /// Cancel a booking
        /// </summary>
        [HttpPost("{bookingId}/cancel")]
        public async Task<IActionResult> CancelBooking(Guid bookingId, [FromBody] CancelBookingCommand command)
        {
            command.BookingId = bookingId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث بيانات الحجز
        /// Update booking information
        /// </summary>
        [HttpPut("{bookingId}/update")]
        public async Task<IActionResult> UpdateBooking(Guid bookingId, [FromBody] UpdateBookingCommand command)
        {
            command.BookingId = bookingId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تأكيد الحجز
        /// Confirm a booking
        /// </summary>
        [HttpPost("confirm")]
        public async Task<IActionResult> ConfirmBooking([FromBody] ConfirmBookingCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تأكيد الحجز عبر المعرف في المسار
        /// Confirm booking by id in route (alternative)
        /// </summary>
        [HttpPost("{bookingId}/confirm")]
        public async Task<IActionResult> ConfirmBookingById(Guid bookingId)
        {
            var result = await _mediator.Send(new ConfirmBookingCommand { BookingId = bookingId });
            return Ok(result);
        }

        /// <summary>
        /// تسجيل الوصول للحجز
        /// Check-in booking
        /// </summary>
        [HttpPost("{bookingId}/check-in")]
        public async Task<IActionResult> CheckIn(Guid bookingId)
        {
            var result = await _mediator.Send(new CheckInBookingCommand { BookingId = bookingId });
            return Ok(result);
        }

        /// <summary>
        /// تسجيل المغادرة للحجز
        /// Check-out booking
        /// </summary>
        [HttpPost("{bookingId}/check-out")]
        public async Task<IActionResult> CheckOut(Guid bookingId)
        {
            var result = await _mediator.Send(new CheckOutBookingCommand { BookingId = bookingId });
            return Ok(result);
        }

        /// <summary>
        /// إكمال الحجز
        /// Complete booking
        /// </summary>
        [HttpPost("{bookingId}/complete")]
        public async Task<IActionResult> Complete(Guid bookingId)
        {
            var result = await _mediator.Send(new CompleteBookingCommand { BookingId = bookingId });
            return Ok(result);
        }

        /// <summary>
        /// تسجيل دفعة للحجز
        /// Register a payment for booking
        /// </summary>
        [HttpPost("{bookingId}/register-payment")]
        public async Task<IActionResult> RegisterPayment(Guid bookingId, [FromBody] RegisterBookingPaymentCommand command)
        {
            command.BookingId = bookingId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }


        /// <summary>
        /// جلب بيانات حجز بواسطة المعرف
        /// Get booking details by ID
        /// </summary>
        [HttpGet("{bookingId}")]
        public async Task<IActionResult> GetBookingById(Guid bookingId)
        {
            var query = new GetBookingByIdQuery { BookingId = bookingId };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب تفاصيل الحجز الكاملة (كيانات وخدمات ومدفوعات)
        /// Get full booking details
        /// </summary>
        [HttpGet("{bookingId}/details")]
        public async Task<IActionResult> GetBookingDetails(Guid bookingId)
        {
            var query = new GetBookingByIdQuery { BookingId = bookingId };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب الحجوزات حسب الكيان
        /// Get bookings by property with filters and pagination
        /// </summary>
        [HttpGet("property/{propertyId}")]
        public async Task<IActionResult> GetBookingsByProperty(Guid propertyId, [FromQuery] GetBookingsByPropertyQuery query)
        {
            query.PropertyId = propertyId;
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب الحجوزات حسب الحالة
        /// Get bookings by status with pagination
        /// </summary>
        [HttpGet("status")]
        public async Task<IActionResult> GetBookingsByStatus([FromQuery] GetBookingsByStatusQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب الحجوزات حسب الوحدة
        /// Get bookings by unit
        /// </summary>
        [HttpGet("unit/{unitId}")]
        public async Task<IActionResult> GetBookingsByUnit(Guid unitId, [FromQuery] GetBookingsByUnitQuery query)
        {
            query.UnitId = unitId;
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب الحجوزات حسب المستخدم
        /// Get bookings by user with filters and pagination
        /// </summary>
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetBookingsByUser(Guid userId, [FromQuery] GetBookingsByUserQuery query)
        {
            query.UserId = userId;
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب خدمات الحجز
        /// Get services for a booking
        /// </summary>
        [HttpGet("{bookingId}/services")]
        public async Task<IActionResult> GetBookingServices(Guid bookingId)
        {
            var query = new GetBookingServicesQuery { BookingId = bookingId };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام تقرير الحجوزات
        /// Get booking report
        /// </summary>
        [HttpGet("report")]
        public async Task<IActionResult> GetBookingReport([FromQuery] GetBookingReportQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام اتجاهات الحجوزات كسلسلة زمنية
        /// Get booking trends as time series
        /// </summary>
        [HttpGet("trends")]
        public async Task<IActionResult> GetBookingTrends([FromQuery] GetBookingTrendsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام تحليل نافذة الحجز لكيان معين
        /// Get booking window analysis for a specific property
        /// </summary>
        [HttpGet("window-analysis/{propertyId}")]
        public async Task<IActionResult> GetBookingWindowAnalysis(Guid propertyId)
        {
            var query = new GetBookingWindowAnalysisQuery(propertyId);
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام الحجوزات في نطاق زمني
        /// Get bookings by date range
        /// </summary>
        [HttpGet("by-date-range")]
        public async Task<IActionResult> GetBookingsByDateRange([FromQuery] GetBookingsByDateRangeQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
} 