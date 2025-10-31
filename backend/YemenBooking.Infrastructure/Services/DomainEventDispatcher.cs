using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// موزع أحداث المجال - يقوم بنشر أحداث المجال بعد حفظ التغييرات
    /// </summary>
    public class DomainEventDispatcher : IDomainEventDispatcher
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<DomainEventDispatcher> _logger;
        private readonly List<object> _events;

        public DomainEventDispatcher(IServiceProvider serviceProvider, ILogger<DomainEventDispatcher> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
            _events = new List<object>();
        }

        /// <summary>
        /// إضافة حدث للقائمة
        /// </summary>
        void IDomainEventDispatcher.AddEvent(IDomainEvent domainEvent)
        {
            _events.Add(domainEvent);
        }

        /// <summary>
        /// نشر جميع الأحداث المجمعة
        /// </summary>
        public async Task DispatchAsync()
        {
            try
            {
                var tasks = new List<Task>();

                foreach (var domainEvent in _events.ToList())
                {
                    tasks.Add(DispatchEventAsync(domainEvent));
                }

                await Task.WhenAll(tasks);
                _events.Clear();

                _logger.LogInformation($"تم نشر {tasks.Count} حدث مجال بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في نشر أحداث المجال");
                throw;
            }
        }

        /// <summary>
        /// نشر حدث واحد
        /// </summary>
        private async Task DispatchEventAsync(object domainEvent)
        {
            try
            {
                var eventType = domainEvent.GetType();
                var handlerType = typeof(IDomainEventHandler<>).MakeGenericType(eventType);

                using var scope = _serviceProvider.CreateScope();
                var handlers = scope.ServiceProvider.GetServices(handlerType);

                var tasks = handlers.Select(handler =>
                {
                    var method = handlerType.GetMethod("Handle");
                    return (Task)method.Invoke(handler, new[] { domainEvent });
                });

                await Task.WhenAll(tasks);

                _logger.LogDebug($"تم نشر الحدث {eventType.Name} بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"خطأ في نشر الحدث {domainEvent.GetType().Name}");
                throw;
            }
        }

        /// <summary>
        /// مسح جميع الأحداث
        /// </summary>
        public void ClearEvents()
        {
            _events.Clear();
        }

        async Task IDomainEventDispatcher.DispatchAsync() => await DispatchAsync();
    }
}