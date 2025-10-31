using System;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Users.Commands.CreateUser;
using YemenBooking.Application.Features.Users.Commands.UpdateUser;
using YemenBooking.Application.Features.Users.Commands.DeleteUser;
using YemenBooking.Application.Features.Users.Commands.ManageRoles;
using YemenBooking.Application.Features.Users.Queries.SearchUsers;
using YemenBooking.Application.Features.Users.Queries.GetAllUsers;
using YemenBooking.Application.Features.Users.Queries.GetUserById;
using YemenBooking.Application.Features.Users.Queries.GetUserDetails;
using YemenBooking.Application.Features.Users.Queries.GetUsersByRole;
using YemenBooking.Application.Features.Users.Queries.GetUserStatisticsStatistics;
using YemenBooking.Application.Features.Notifications.Queries.GetUserNotifications;
using YemenBooking.Application.Features.Authentication.Commands.RegisterOwner;
using YemenBooking.Application.Features.Analytics.Queries.UserAnalytics;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بإدارة المستخدمين (إنشاء، تعديل، حذف، تمكين/تعطيل، تخصيص الأدوار)
    /// Controller for user management by admin
    /// </summary>
    public class UsersController : BaseAdminController
    {
        public UsersController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// البحث عن المستخدمين مع الفلاتر والفرز
        /// Search users with filters, sorting, and pagination
        /// </summary>
        [HttpGet("search")]
        public async Task<IActionResult> SearchUsers([FromQuery] SearchUsersQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب جميع المستخدمين
        /// Get all users with optional search, sorting, and pagination
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAllUsers([FromQuery] GetAllUsersQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب بيانات مستخدم بواسطة المعرف
        /// Get user details by ID
        /// </summary>
        [HttpGet("{id}")]
        public async Task<IActionResult> GetUserById(Guid id)
        {
            var query = new GetUserByIdQuery { UserId = id };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// إنشاء مستخدم جديد
        /// Create a new user
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تسجيل مالك كيان جديد وإنشاء العقار المرتبط (عملية واحدة)
        /// Register new property owner and create the linked property (single operation)
        /// </summary>
        [HttpPost("register-owner")]
        public async Task<IActionResult> RegisterPropertyOwner([FromBody] RegisterPropertyOwnerCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث بيانات مستخدم
        /// Update an existing user
        /// </summary>
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUser(Guid id, [FromBody] UpdateUserCommand command)
        {
            command.UserId = id;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تفعيل حساب المستخدم
        /// Activate a user account
        /// </summary>
        [HttpPost("{id}/activate")]
        public async Task<IActionResult> ActivateUser(Guid id)
        {
            var command = new ActivateUserCommand { UserId = id };
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إلغاء تفعيل حساب المستخدم
        /// Deactivate a user account
        /// </summary>
        [HttpPost("{id}/deactivate")]
        public async Task<IActionResult> DeactivateUser(Guid id)
        {
            var command = new DeactivateUserCommand { UserId = id };
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تخصيص دور للمستخدم
        /// Assign a role to a user
        /// </summary>
        [HttpPost("{id}/assign-role")]
        public async Task<IActionResult> AssignUserRole(Guid id, [FromBody] AssignUserRoleCommand command)
        {
            command.UserId = id;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// استعلام المستخدمين حسب الدور
        /// Get users by role
        /// </summary>
        [HttpGet("by-role")]
        public async Task<IActionResult> GetUsersByRole([FromQuery] GetUsersByRoleQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام إحصائيات المستخدم مدى الحياة
        /// Get user lifetime statistics
        /// </summary>
        [HttpGet("{id}/lifetime-stats")]
        public async Task<IActionResult> GetUserLifetimeStats(Guid id)
        {
            var query = new GetUserLifetimeStatsQuery(id);
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام إشعارات المستخدم
        /// Get user notifications
        /// </summary>
        [HttpGet("{id}/notifications")]
        public async Task<IActionResult> GetUserNotifications(Guid id, [FromQuery] GetUserNotificationsQuery query)
        {
            query.UserId = id;
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام تفاصيل مستخدم بواسطة المعرف
        /// </summary>
        [HttpGet("{id}/details")]
        public async Task<IActionResult> GetUserDetails(Guid id)
        {
            var query = new GetUserDetailsQuery { UserId = id };
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
} 