using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace YemenBooking.Api.Controllers
{
    /// <summary>
    /// Controller لاختبار وظيفة تتبع آخر ظهور المستخدمين
    /// Test controller for LastSeen tracking functionality
    /// </summary>
    [ApiController]
    [Route("api/test/[controller]")]
    public class TestLastSeenController : ControllerBase
    {
        private readonly global::YemenBooking.Infrastructure.Data.Context.YemenBookingDbContext _dbContext;
        private readonly ILogger<TestLastSeenController> _logger;

        public TestLastSeenController(
            global::YemenBooking.Infrastructure.Data.Context.YemenBookingDbContext dbContext,
            ILogger<TestLastSeenController> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        /// <summary>
        /// الحصول على معلومات آخر ظهور للمستخدم الحالي
        /// Get current user's last seen information
        /// </summary>
        [HttpGet("current")]
        [Authorize]
        public async Task<IActionResult> GetCurrentUserLastSeen()
        {
            try
            {
                var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)
                                 ?? User.FindFirst("id")
                                 ?? User.FindFirst("sub")
                                 ?? User.FindFirst("userId");

                if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
                {
                    return BadRequest(new { message = "Unable to identify user" });
                }

                var user = await _dbContext.Users
                    .Where(u => u.Id == userId)
                    .Select(u => new
                    {
                        u.Id,
                        u.Name,
                        u.Email,
                        u.LastLoginDate,
                        u.LastSeen,
                        TimeSinceLastSeen = u.LastSeen.HasValue 
                            ? (DateTime.UtcNow - u.LastSeen.Value).TotalSeconds 
                            : (double?)null
                    })
                    .FirstOrDefaultAsync();

                if (user == null)
                {
                    return NotFound(new { message = "User not found" });
                }

                return Ok(new
                {
                    success = true,
                    data = user,
                    serverTime = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting current user LastSeen");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        /// <summary>
        /// الحصول على قائمة المستخدمين النشطين (آخر ظهور خلال 5 دقائق)
        /// Get list of online users (last seen within 5 minutes)
        /// </summary>
        [HttpGet("online-users")]
        [Authorize]
        public async Task<IActionResult> GetOnlineUsers()
        {
            try
            {
                var fiveMinutesAgo = DateTime.UtcNow.AddMinutes(-5);

                var onlineUsers = await _dbContext.Users
                    .Where(u => u.LastSeen != null && u.LastSeen > fiveMinutesAgo)
                    .Select(u => new
                    {
                        u.Id,
                        u.Name,
                        u.Email,
                        u.LastSeen,
                        IsOnline = true
                    })
                    .OrderByDescending(u => u.LastSeen)
                    .Take(50) // حد أقصى 50 مستخدم
                    .ToListAsync();

                return Ok(new
                {
                    success = true,
                    count = onlineUsers.Count,
                    data = onlineUsers,
                    serverTime = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting online users");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        /// <summary>
        /// الحصول على إحصائيات نشاط المستخدمين
        /// Get user activity statistics
        /// </summary>
        [HttpGet("activity-stats")]
        [Authorize]
        public async Task<IActionResult> GetActivityStats()
        {
            try
            {
                var now = DateTime.UtcNow;
                var oneMinuteAgo = now.AddMinutes(-1);
                var fiveMinutesAgo = now.AddMinutes(-5);
                var oneHourAgo = now.AddHours(-1);
                var oneDayAgo = now.AddDays(-1);

                var stats = new
                {
                    TotalUsers = await _dbContext.Users.CountAsync(),
                    ActiveLastMinute = await _dbContext.Users
                        .CountAsync(u => u.LastSeen != null && u.LastSeen > oneMinuteAgo),
                    ActiveLast5Minutes = await _dbContext.Users
                        .CountAsync(u => u.LastSeen != null && u.LastSeen > fiveMinutesAgo),
                    ActiveLastHour = await _dbContext.Users
                        .CountAsync(u => u.LastSeen != null && u.LastSeen > oneHourAgo),
                    ActiveLastDay = await _dbContext.Users
                        .CountAsync(u => u.LastSeen != null && u.LastSeen > oneDayAgo),
                    NeverActive = await _dbContext.Users
                        .CountAsync(u => u.LastSeen == null),
                    ServerTime = now
                };

                return Ok(new
                {
                    success = true,
                    data = stats
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting activity statistics");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        /// <summary>
        /// تحديث آخر ظهور يدوياً (لأغراض الاختبار فقط)
        /// Manually update last seen (for testing purposes only)
        /// </summary>
        [HttpPost("update-manually")]
        [Authorize]
        public async Task<IActionResult> UpdateLastSeenManually()
        {
            try
            {
                var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)
                                 ?? User.FindFirst("id")
                                 ?? User.FindFirst("sub")
                                 ?? User.FindFirst("userId");

                if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
                {
                    return BadRequest(new { message = "Unable to identify user" });
                }

                var now = DateTime.UtcNow;
                var updateResult = await _dbContext.Users
                    .Where(u => u.Id == userId)
                    .ExecuteUpdateAsync(setters => setters
                        .SetProperty(u => u.LastSeen, now));

                if (updateResult > 0)
                {
                    _logger.LogInformation($"Manually updated LastSeen for user {userId} at {now}");
                    return Ok(new
                    {
                        success = true,
                        message = "LastSeen updated successfully",
                        lastSeen = now
                    });
                }

                return NotFound(new { message = "User not found" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error manually updating LastSeen");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        /// <summary>
        /// الحصول على سجل نشاط المستخدمين
        /// Get user activity log
        /// </summary>
        [HttpGet("activity-log")]
        [Authorize]
        public async Task<IActionResult> GetActivityLog([FromQuery] int hours = 24)
        {
            try
            {
                if (hours < 1 || hours > 168) // Max 7 days
                {
                    return BadRequest(new { message = "Hours must be between 1 and 168" });
                }

                var sinceTime = DateTime.UtcNow.AddHours(-hours);

                var activityLog = await _dbContext.Users
                    .Where(u => u.LastSeen != null && u.LastSeen > sinceTime)
                    .OrderByDescending(u => u.LastSeen)
                    .Select(u => new
                    {
                        u.Id,
                        u.Name,
                        u.Email,
                        u.LastSeen,
                        u.LastLoginDate,
                        MinutesSinceLastSeen = u.LastSeen.HasValue 
                            ? (int)(DateTime.UtcNow - u.LastSeen.Value).TotalMinutes
                            : (int?)null
                    })
                    .Take(100)
                    .ToListAsync();

                return Ok(new
                {
                    success = true,
                    hoursRequested = hours,
                    count = activityLog.Count,
                    data = activityLog,
                    serverTime = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting activity log");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }
    }
}
