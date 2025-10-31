namespace YemenBooking.Application.Common.Interfaces;

/// <summary>
/// واجهة خدمة نشر الأحداث
/// Event publisher service interface
/// </summary>
public interface IEventPublisher
{
    /// <summary>
    /// نشر حدث
    /// Publish event
    /// </summary>
    Task<bool> PublishEventAsync<T>(T eventData, CancellationToken cancellationToken = default) where T : class;

    /// <summary>
    /// نشر حدث مع تأخير
    /// Publish event with delay
    /// </summary>
    Task<bool> PublishEventWithDelayAsync<T>(
        T eventData,
        TimeSpan delay,
        CancellationToken cancellationToken = default) where T : class;

    /// <summary>
    /// نشر أحداث متعددة
    /// Publish multiple events
    /// </summary>
    Task<bool> PublishEventsAsync<T>(
        IEnumerable<T> events,
        CancellationToken cancellationToken = default) where T : class;

    /// <summary>
    /// نشر حدث مشروط
    /// Publish conditional event
    /// </summary>
    Task<bool> PublishEventIfAsync<T>(
        T eventData,
        Func<T, bool> condition,
        CancellationToken cancellationToken = default) where T : class;

    /// <summary>
    /// ينشر حدثًا باستخدام PublishEventAsync تحت الاسم المستعار PublishAsync.
    /// </summary>
    Task<bool> PublishAsync<T>(T eventData, CancellationToken cancellationToken = default) where T : class;


}
