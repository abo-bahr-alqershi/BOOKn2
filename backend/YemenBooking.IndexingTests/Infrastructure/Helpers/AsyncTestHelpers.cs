using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Linq.Expressions;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore.Query;
using Polly;
using Xunit.Abstractions;

namespace YemenBooking.IndexingTests.Infrastructure.Helpers
{
    /// <summary>
    /// Helper classes for async testing with Entity Framework mocks
    /// </summary>
    public class TestAsyncQueryProvider<TEntity> : IAsyncQueryProvider
    {
        private readonly IQueryProvider _inner;

        internal TestAsyncQueryProvider(IQueryProvider inner)
        {
            _inner = inner;
        }

        public IQueryable CreateQuery(Expression expression)
        {
            return new TestAsyncEnumerable<TEntity>(expression);
        }

        public IQueryable<TElement> CreateQuery<TElement>(Expression expression)
        {
            return new TestAsyncEnumerable<TElement>(expression);
        }

        public object Execute(Expression expression)
        {
            return _inner.Execute(expression);
        }

        public TResult Execute<TResult>(Expression expression)
        {
            return _inner.Execute<TResult>(expression);
        }

        public TResult ExecuteAsync<TResult>(Expression expression, CancellationToken cancellationToken = default)
        {
            return Execute<TResult>(expression);
        }
    }

    public class TestAsyncEnumerable<T> : EnumerableQuery<T>, IAsyncEnumerable<T>, IQueryable<T>
    {
        public TestAsyncEnumerable(IEnumerable<T> enumerable)
            : base(enumerable)
        {
        }

        public TestAsyncEnumerable(Expression expression)
            : base(expression)
        {
        }

        public IAsyncEnumerator<T> GetAsyncEnumerator(CancellationToken cancellationToken = default)
        {
            return new TestAsyncEnumerator<T>(this.AsEnumerable().GetEnumerator());
        }

        IQueryProvider IQueryable.Provider
        {
            get { return new TestAsyncQueryProvider<T>(this); }
        }
    }

    public class TestAsyncEnumerator<T> : IAsyncEnumerator<T>
    {
        private readonly IEnumerator<T> _inner;

        public TestAsyncEnumerator(IEnumerator<T> inner)
        {
            _inner = inner;
        }

        public T Current => _inner.Current;

        public ValueTask<bool> MoveNextAsync()
        {
            return new ValueTask<bool>(_inner.MoveNext());
        }

        public ValueTask DisposeAsync()
        {
            _inner.Dispose();
            return new ValueTask();
        }
    }
    
    /// <summary>
    /// أدوات مساعدة للعمليات غير المتزامنة والانتظار
    /// تطبق مبدأ الحتمية - لا Task.Delay ثابت
    /// </summary>
    public static class AsyncTestOperations
    {
        /// <summary>
        /// انتظار شرط باستخدام Polling Pattern الصحيح
        /// </summary>
        public static async Task<T> WaitForConditionAsync<T>(
            Func<Task<T>> checkCondition,
            Func<T, bool> isConditionMet,
            TimeSpan timeout,
            TimeSpan? pollInterval = null,
            CancellationToken cancellationToken = default)
        {
            pollInterval ??= TimeSpan.FromMilliseconds(50);
            var deadline = DateTime.UtcNow.Add(timeout);
            var stopwatch = Stopwatch.StartNew();
            
            while (DateTime.UtcNow < deadline && !cancellationToken.IsCancellationRequested)
            {
                try
                {
                    var result = await checkCondition();
                    if (isConditionMet(result))
                    {
                        return result;
                    }
                }
                catch (Exception) when (!cancellationToken.IsCancellationRequested)
                {
                    // Continue polling on transient errors
                }
                
                var remainingTime = deadline - DateTime.UtcNow;
                if (remainingTime <= TimeSpan.Zero)
                    break;
                    
                var delay = remainingTime < pollInterval.Value ? remainingTime : pollInterval.Value;
                await Task.Delay(delay, cancellationToken);
            }
            
            cancellationToken.ThrowIfCancellationRequested();
            throw new TimeoutException($"Condition not met within {timeout.TotalSeconds} seconds");
        }
        
        /// <summary>
        /// انتظار شرط باستخدام Eventually Consistent Pattern
        /// </summary>
        public static async Task AssertEventuallyAsync(
            Func<Task<bool>> assertion,
            TimeSpan timeout,
            string message = null,
            TimeSpan? pollInterval = null)
        {
            try
            {
                await WaitForConditionAsync(
                    assertion,
                    result => result,
                    timeout,
                    pollInterval);
            }
            catch (TimeoutException)
            {
                throw new AssertionException(message ?? "Assertion did not become true within timeout");
            }
        }
        
        /// <summary>
        /// تنفيذ عملية مع إعادة المحاولة باستخدام Polly
        /// </summary>
        public static async Task<T> ExecuteWithRetryAsync<T>(
            Func<Task<T>> operation,
            int maxAttempts = 3,
            Func<Exception, bool> shouldRetry = null,
            ITestOutputHelper output = null)
        {
            shouldRetry ??= ex => ex is TransientException || ex is TimeoutException;
            
            var policy = Policy<T>
                .HandleResult(r => false) // Don't retry on result
                .OrInner(shouldRetry)
                .WaitAndRetryAsync(
                    retryCount: maxAttempts - 1,
                    sleepDurationProvider: retryAttempt => TimeSpan.FromMilliseconds(Math.Pow(2, retryAttempt) * 100),
                    onRetry: (outcome, timespan, retryCount, context) =>
                    {
                        var message = outcome.Exception != null 
                            ? $"Retry {retryCount} after {timespan.TotalMilliseconds}ms due to: {outcome.Exception.Message}"
                            : $"Retry {retryCount} after {timespan.TotalMilliseconds}ms";
                        
                        output?.WriteLine(message);
                    });
            
            return await policy.ExecuteAsync(operation);
        }
        
        /// <summary>
        /// تنفيذ عملية مع Timeout
        /// </summary>
        public static async Task<T> ExecuteWithTimeoutAsync<T>(
            Func<CancellationToken, Task<T>> operation,
            TimeSpan timeout)
        {
            using var cts = new CancellationTokenSource(timeout);
            
            try
            {
                return await operation(cts.Token);
            }
            catch (OperationCanceledException) when (cts.IsCancellationRequested)
            {
                throw new TimeoutException($"Operation timed out after {timeout.TotalSeconds} seconds");
            }
        }
        
        /// <summary>
        /// انتظار مجموعة من المهام مع timeout لكل مهمة
        /// </summary>
        public static async Task<T[]> WaitAllWithTimeoutAsync<T>(
            IEnumerable<Task<T>> tasks,
            TimeSpan timeout)
        {
            var taskList = tasks.ToList();
            using var cts = new CancellationTokenSource(timeout);
            
            var completedTask = await Task.WhenAny(
                Task.WhenAll(taskList),
                Task.Delay(timeout, cts.Token));
            
            if (completedTask is Task<T[]> results)
            {
                cts.Cancel(); // Cancel the delay task
                return await results;
            }
            
            throw new TimeoutException($"Tasks did not complete within {timeout.TotalSeconds} seconds");
        }
        
        /// <summary>
        /// تنفيذ عمليات متوازية مع تحديد العدد الأقصى
        /// </summary>
        public static async Task<TResult[]> ExecuteParallelAsync<TSource, TResult>(
            IEnumerable<TSource> source,
            Func<TSource, Task<TResult>> operation,
            int maxDegreeOfParallelism = 4)
        {
            using var semaphore = new SemaphoreSlim(maxDegreeOfParallelism);
            
            var tasks = source.Select(async item =>
            {
                await semaphore.WaitAsync();
                try
                {
                    return await operation(item);
                }
                finally
                {
                    semaphore.Release();
                }
            });
            
            return await Task.WhenAll(tasks);
        }
        
        /// <summary>
        /// قياس أداء العملية
        /// </summary>
        public static async Task<(T Result, PerformanceMetrics Metrics)> MeasurePerformanceAsync<T>(
            Func<Task<T>> operation)
        {
            var initialMemory = GC.GetTotalMemory(true);
            var stopwatch = Stopwatch.StartNew();
            
            var result = await operation();
            
            stopwatch.Stop();
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            
            var finalMemory = GC.GetTotalMemory(false);
            
            return (result, new PerformanceMetrics
            {
                Duration = stopwatch.Elapsed,
                MemoryUsed = finalMemory - initialMemory,
                MemoryUsedMB = (finalMemory - initialMemory) / (1024.0 * 1024.0)
            });
        }
    }
    
    /// <summary>
    /// معلومات الأداء
    /// </summary>
    public class PerformanceMetrics
    {
        public TimeSpan Duration { get; set; }
        public long MemoryUsed { get; set; }
        public double MemoryUsedMB { get; set; }
        
        public override string ToString()
        {
            return $"Duration: {Duration.TotalMilliseconds}ms, Memory: {MemoryUsedMB:F2}MB";
        }
    }
    
    /// <summary>
    /// استثناءات مخصصة للاختبارات
    /// </summary>
    public class AssertionException : Exception
    {
        public AssertionException(string message) : base(message) { }
        public AssertionException(string message, Exception innerException) : base(message, innerException) { }
    }
    
    public class TransientException : Exception
    {
        public TransientException(string message) : base(message) { }
        public TransientException(string message, Exception innerException) : base(message, innerException) { }
    }
}
