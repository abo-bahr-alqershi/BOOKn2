using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.IndexingTests.Infrastructure
{
    /// <summary>
    /// الفئة الأساسية لجميع الاختبارات - بدون static state
    /// كل اختبار معزول تماماً عن الآخر
    /// </summary>
    public abstract class TestBase : IAsyncLifetime, IDisposable
    {
        protected readonly ITestOutputHelper Output;
        protected readonly IServiceProvider ServiceProvider;
        protected readonly IServiceScope TestScope;
        protected readonly string TestId;
        protected readonly CancellationTokenSource TestCancellation;
        
        // خدمات أساسية لكل اختبار
        protected readonly YemenBookingDbContext DbContext;
        protected readonly IIndexingService IndexingService;
        protected readonly ILogger<TestBase> Logger;
        
        // للتتبع والتنظيف
        private readonly List<Guid> _trackedEntities = new();
        private readonly List<IDisposable> _disposables = new();
        
        protected TestBase(ITestOutputHelper output)
        {
            Output = output ?? throw new ArgumentNullException(nameof(output));
            TestId = $"Test_{Guid.NewGuid():N}";
            TestCancellation = new CancellationTokenSource();
            
            // سيتم تهيئة الخدمات في InitializeAsync
        }
        
        /// <summary>
        /// تهيئة الاختبار - يتم استدعاؤها قبل كل اختبار
        /// </summary>
        public virtual async Task InitializeAsync()
        {
            Output.WriteLine($"🚀 Initializing test: {TestId}");
            
            // إنشاء ServiceProvider مخصص لهذا الاختبار
            var services = new ServiceCollection();
            await ConfigureServicesAsync(services);
            
            var provider = services.BuildServiceProvider();
            _disposables.Add(provider);
            
            // إنشاء scope منفصل للاختبار
            TestScope = provider.CreateScope();
            _disposables.Add(TestScope);
            
            ServiceProvider = TestScope.ServiceProvider;
            
            // الحصول على الخدمات الأساسية
            DbContext = ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            IndexingService = ServiceProvider.GetRequiredService<IIndexingService>();
            Logger = ServiceProvider.GetRequiredService<ILogger<TestBase>>();
            
            // تهيئة قاعدة البيانات
            await InitializeDatabaseAsync();
            
            Output.WriteLine($"✅ Test {TestId} initialized successfully");
        }
        
        /// <summary>
        /// تكوين الخدمات للاختبار - يمكن للفئات المشتقة تخصيصها
        /// </summary>
        protected virtual async Task ConfigureServicesAsync(IServiceCollection services)
        {
            // سيتم تنفيذها في الفئات المشتقة
            await Task.CompletedTask;
        }
        
        /// <summary>
        /// تهيئة قاعدة البيانات للاختبار
        /// </summary>
        protected virtual async Task InitializeDatabaseAsync()
        {
            // سيتم تنفيذها في الفئات المشتقة
            await Task.CompletedTask;
        }
        
        /// <summary>
        /// تنظيف الاختبار - يتم استدعاؤها بعد كل اختبار
        /// </summary>
        public virtual async Task DisposeAsync()
        {
            Output.WriteLine($"🧹 Cleaning up test: {TestId}");
            
            try
            {
                // إلغاء أي عمليات جارية
                TestCancellation.Cancel();
                
                // تنظيف الكيانات المتتبعة
                await CleanupTrackedEntitiesAsync();
                
                // تنظيف الموارد
                foreach (var disposable in _disposables.AsEnumerable().Reverse())
                {
                    try
                    {
                        disposable?.Dispose();
                    }
                    catch (Exception ex)
                    {
                        Output.WriteLine($"⚠️ Error disposing resource: {ex.Message}");
                    }
                }
                
                Output.WriteLine($"✅ Test {TestId} cleaned up successfully");
            }
            catch (Exception ex)
            {
                Output.WriteLine($"❌ Error during cleanup: {ex.Message}");
            }
        }
        
        public virtual void Dispose()
        {
            // التنظيف الإضافي إذا لزم
            TestCancellation?.Dispose();
        }
        
        #region Helper Methods
        
        /// <summary>
        /// إنشاء scope منفصل للعمليات المتزامنة
        /// </summary>
        protected IServiceScope CreateIsolatedScope()
        {
            var scope = ServiceProvider.CreateScope();
            _disposables.Add(scope);
            return scope;
        }
        
        /// <summary>
        /// تتبع كيان للتنظيف التلقائي
        /// </summary>
        protected void TrackEntity(Guid entityId)
        {
            _trackedEntities.Add(entityId);
        }
        
        /// <summary>
        /// تتبع عدة كيانات للتنظيف
        /// </summary>
        protected void TrackEntities(IEnumerable<Guid> entityIds)
        {
            _trackedEntities.AddRange(entityIds);
        }
        
        /// <summary>
        /// تنظيف الكيانات المتتبعة
        /// </summary>
        protected virtual async Task CleanupTrackedEntitiesAsync()
        {
            if (!_trackedEntities.Any())
                return;
                
            try
            {
                Output.WriteLine($"🗑️ Cleaning up {_trackedEntities.Count} tracked entities");
                
                // التنظيف سيتم تنفيذه في الفئات المشتقة حسب نوع قاعدة البيانات
                await PerformEntityCleanupAsync(_trackedEntities);
                
                _trackedEntities.Clear();
            }
            catch (Exception ex)
            {
                Output.WriteLine($"⚠️ Error cleaning tracked entities: {ex.Message}");
            }
        }
        
        /// <summary>
        /// تنفيذ التنظيف الفعلي للكيانات - يتم تنفيذها في الفئات المشتقة
        /// </summary>
        protected virtual async Task PerformEntityCleanupAsync(List<Guid> entityIds)
        {
            await Task.CompletedTask;
        }
        
        /// <summary>
        /// انتظار شرط معين مع timeout - polling pattern
        /// </summary>
        protected async Task<T> WaitForConditionAsync<T>(
            Func<Task<T>> checkCondition,
            Func<T, bool> isConditionMet,
            TimeSpan timeout,
            TimeSpan? pollInterval = null)
        {
            pollInterval ??= TimeSpan.FromMilliseconds(100);
            var deadline = DateTime.UtcNow.Add(timeout);
            
            while (DateTime.UtcNow < deadline)
            {
                TestCancellation.Token.ThrowIfCancellationRequested();
                
                var result = await checkCondition();
                if (isConditionMet(result))
                {
                    return result;
                }
                
                var remainingTime = deadline - DateTime.UtcNow;
                if (remainingTime <= TimeSpan.Zero)
                    break;
                    
                var delay = remainingTime < pollInterval.Value ? remainingTime : pollInterval.Value;
                await Task.Delay(delay, TestCancellation.Token);
            }
            
            throw new TimeoutException($"Condition not met within {timeout}");
        }
        
        /// <summary>
        /// انتظار حتى يصبح شرط صحيحاً
        /// </summary>
        protected async Task WaitUntilAsync(
            Func<Task<bool>> condition,
            TimeSpan timeout,
            string timeoutMessage = null)
        {
            await WaitForConditionAsync(
                condition,
                result => result,
                timeout);
        }
        
        /// <summary>
        /// قياس وقت التنفيذ
        /// </summary>
        protected async Task<(T Result, TimeSpan Duration)> MeasureAsync<T>(Func<Task<T>> operation)
        {
            var stopwatch = System.Diagnostics.Stopwatch.StartNew();
            var result = await operation();
            stopwatch.Stop();
            
            Output.WriteLine($"⏱️ Operation completed in {stopwatch.ElapsedMilliseconds}ms");
            return (result, stopwatch.Elapsed);
        }
        
        /// <summary>
        /// تنفيذ عملية مع إعادة المحاولة
        /// </summary>
        protected async Task<T> RetryAsync<T>(
            Func<Task<T>> operation,
            int maxAttempts = 3,
            TimeSpan? delay = null)
        {
            delay ??= TimeSpan.FromSeconds(1);
            
            for (int attempt = 1; attempt <= maxAttempts; attempt++)
            {
                try
                {
                    return await operation();
                }
                catch (Exception ex) when (attempt < maxAttempts)
                {
                    Output.WriteLine($"⚠️ Attempt {attempt} failed: {ex.Message}. Retrying...");
                    await Task.Delay(delay.Value, TestCancellation.Token);
                }
            }
            
            // المحاولة الأخيرة - دع الاستثناء يظهر
            return await operation();
        }
        
        #endregion
    }
}
