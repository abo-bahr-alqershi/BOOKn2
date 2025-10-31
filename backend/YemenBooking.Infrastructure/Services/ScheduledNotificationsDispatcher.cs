using System;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Infrastructure.Data.Context;
using INotificationService = YemenBooking.Application.Features.Notifications.Services.INotificationService;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// خدمة مستضافة ترسل الإشعارات المجدولة أو المعلقة بشكل دوري
    /// Background dispatcher to send scheduled/pending notifications
    /// </summary>
    public class ScheduledNotificationsDispatcher : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<ScheduledNotificationsDispatcher> _logger;

        public ScheduledNotificationsDispatcher(IServiceProvider serviceProvider, ILogger<ScheduledNotificationsDispatcher> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("ScheduledNotificationsDispatcher started");
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using var scope = _serviceProvider.CreateScope();
                    var db = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                    var notifier = scope.ServiceProvider.GetRequiredService<INotificationService>();

                    var now = DateTime.UtcNow;
                    var due = await db.Set<Notification>()
                        .Where(n => n.Status == "PENDING" && (!n.ScheduledFor.HasValue || n.ScheduledFor <= now) && !n.IsDeleted)
                        .OrderBy(n => n.CreatedAt)
                        .Take(100)
                        .ToListAsync(stoppingToken);

                    foreach (var n in due)
                    {
                        try
                        {
                            await notifier.SendAsync(new YemenBooking.Core.Notifications.NotificationRequest
                            {
                                UserId = n.RecipientId,
                                Title = n.Title,
                                Message = n.Message,
                                Type = Enum.TryParse<YemenBooking.Core.Notifications.NotificationType>(n.Type, true, out var t)
                                    ? t : YemenBooking.Core.Notifications.NotificationType.BookingUpdated,
                                Data = string.IsNullOrWhiteSpace(n.Data) ? null : JsonSerializer.Deserialize<object>(n.Data)
                            }, stoppingToken);
                            n.MarkAsSent("IN_APP");
                            n.MarkAsDelivered();
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "Failed to dispatch notification {Id}", n.Id);
                            n.MarkAsFailed(ex.Message);
                        }
                    }

                    if (due.Count > 0)
                        await db.SaveChangesAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in ScheduledNotificationsDispatcher loop");
                }

                await Task.Delay(TimeSpan.FromSeconds(15), stoppingToken);
            }
        }
    }
}

