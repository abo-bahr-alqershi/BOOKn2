using System;
using System.Linq;
using System.Threading.Tasks;
using FirebaseAdmin.Messaging;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Authorization; // added for Authorize attribute
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Api.Controllers.Common
{
    /// <summary>
    /// متحكم لتسجيل رموز Firebase للمستخدمين
    /// Controller for registering user FCM tokens and topic subscription
    /// </summary>
    [ApiController]
    [Authorize]
    [Route("api/fcm")]
    public class FcmController : ControllerBase
    {
        private readonly ILogger<FcmController> _logger;
        private readonly ICurrentUserService _currentUser;

        public FcmController(ILogger<FcmController> logger, ICurrentUserService currentUser)
        {
            _logger = logger;
            _currentUser = currentUser;
        }

        /// <summary>
        /// تسجيل رمز FCM لمستخدم والاشتراك بموضوع الرسائل الخاص به
        /// Register FCM token and subscribe to user topic
        /// </summary>
        [HttpPost("register")]
        public async Task<IActionResult> RegisterToken([FromBody] RegisterFcmTokenRequest request)
        {
            try
            {
                var tokenArr = new[] { request.Token };

                // enforce security: always use the authenticated user id from context
                var userId = _currentUser.UserId;

                // اشتراك موضوع المستخدم (user_{userId})
                var userTopic = $"user_{userId}";
                await FirebaseMessaging.DefaultInstance.SubscribeToTopicAsync(tokenArr, userTopic);
                _logger.LogInformation("Subscribed FCM token to topic {Topic} for user {UserId}", userTopic, userId);

                // اشتراك موضوع الجميع فقط للمستخدمين النهائيين (غير المدراء/المالكين/الموظفين)
                if (ShouldSubscribeAllForCurrentUser())
                {
                    await FirebaseMessaging.DefaultInstance.SubscribeToTopicAsync(tokenArr, "all");
                    _logger.LogInformation("Subscribed FCM token to topic {Topic} for user {UserId}", "all", userId);
                }

                // اشتراك مواضيع الأدوار
                var roleTopics = (_currentUser.UserRoles ?? Enumerable.Empty<string>())
                    .Where(r => !string.IsNullOrWhiteSpace(r))
                    .Select(r => $"role_{r.Trim().ToLowerInvariant()}")
                    .Distinct()
                    .ToArray();

                foreach (var roleTopic in roleTopics)
                {
                    await FirebaseMessaging.DefaultInstance.SubscribeToTopicAsync(tokenArr, roleTopic);
                    _logger.LogInformation("Subscribed FCM token to topic {Topic} for user {UserId}", roleTopic, userId);
                }

                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تسجيل رمز FCM أو الاشتراك في الموضوع");
                return StatusCode(500, "خطأ في الخادم أثناء تسجيل الرمز");
            }
        }

        /// <summary>
        /// إلغاء تسجيل رمز FCM لمستخدم وإلغاء الاشتراك من موضوع الرسائل الخاص به
        /// Unregister FCM token and unsubscribe from user topic
        /// </summary>
        [HttpPost("unregister")]
        public async Task<IActionResult> UnregisterToken([FromBody] RegisterFcmTokenRequest request)
        {
            try
            {
                var tokenArr = new[] { request.Token };

                // enforce security: always use the authenticated user id from context
                var userId = _currentUser.UserId;

                // إلغاء الاشتراك من موضوع المستخدم
                var userTopic = $"user_{userId}";
                await FirebaseMessaging.DefaultInstance.UnsubscribeFromTopicAsync(tokenArr, userTopic);
                _logger.LogInformation("Unsubscribed FCM token from topic {Topic} for user {UserId}", userTopic, userId);

                // إلغاء الاشتراك من موضوع الجميع فقط إذا كان قد تم الاشتراك به للمستخدم النهائي
                if (ShouldSubscribeAllForCurrentUser())
                {
                    await FirebaseMessaging.DefaultInstance.UnsubscribeFromTopicAsync(tokenArr, "all");
                    _logger.LogInformation("Unsubscribed FCM token from topic {Topic} for user {UserId}", "all", userId);
                }

                // إلغاء الاشتراك من مواضيع الأدوار
                var roleTopics = (_currentUser.UserRoles ?? Enumerable.Empty<string>())
                    .Where(r => !string.IsNullOrWhiteSpace(r))
                    .Select(r => $"role_{r.Trim().ToLowerInvariant()}")
                    .Distinct()
                    .ToArray();

                foreach (var roleTopic in roleTopics)
                {
                    await FirebaseMessaging.DefaultInstance.UnsubscribeFromTopicAsync(tokenArr, roleTopic);
                    _logger.LogInformation("Unsubscribed FCM token from topic {Topic} for user {UserId}", roleTopic, userId);
                }

                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في إلغاء تسجيل رمز FCM أو إلغاء الاشتراك في الموضوع");
                return StatusCode(500, "خطأ في الخادم أثناء إلغاء تسجيل الرمز");
            }
        }

        private bool ShouldSubscribeAllForCurrentUser()
        {
            // Subscribe to "all" only for end-user accounts, not admin/owner/staff panels
            var elevated = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "Admin", "Owner", "Staff"
            };

            var hasElevatedRole = (_currentUser.UserRoles ?? Enumerable.Empty<string>()).Any(r => elevated.Contains(r));
            var accountRole = _currentUser.AccountRole ?? string.Empty;
            if (elevated.Contains(accountRole)) return false;

            // End-user indicators: Guest/Client
            var endUser = (_currentUser.UserRoles ?? Enumerable.Empty<string>()).Any(r =>
                string.Equals(r, "Guest", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(r, "Client", StringComparison.OrdinalIgnoreCase));

            if (!endUser)
            {
                endUser = string.Equals(accountRole, "Guest", StringComparison.OrdinalIgnoreCase) ||
                          string.Equals(accountRole, "Client", StringComparison.OrdinalIgnoreCase);
            }

            return endUser && !hasElevatedRole;
        }
    }

    /// <summary>
    /// نموذج طلب لتسجيل/إلغاء تسجيل رموز FCM
    /// Request model for registering/unregistering FCM tokens
    /// </summary>
    public class RegisterFcmTokenRequest
    {
        /// <summary>
        /// رمز جهاز FCM
        /// FCM device token
        /// </summary>
        public string Token { get; set; } = string.Empty;

        /// <summary>
        /// معرف المستخدم
        /// User identifier
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// نوع الجهاز (web, mobile, etc.)
        /// Device type
        /// </summary>
        public string DeviceType { get; set; } = string.Empty;
    }
} 