using System;
using System.Threading.Tasks;
using FluentAssertions;
using FluentAssertions.Execution;

namespace YemenBooking.IndexingTests.Infrastructure.Assertions
{
    /// <summary>
    /// Assertions مع إعادة المحاولة للعمليات غير المتزامنة
    /// </summary>
    public static class RetryAssertions
    {
        /// <summary>
        /// التحقق من شرط مع إعادة المحاولة
        /// </summary>
        public static async Task AssertEventuallyAsync(
            Func<Task<bool>> assertion,
            TimeSpan timeout,
            TimeSpan? pollInterval = null,
            string message = null)
        {
            pollInterval ??= TimeSpan.FromMilliseconds(100);
            var deadline = DateTime.UtcNow.Add(timeout);
            Exception lastException = null;
            
            while (DateTime.UtcNow < deadline)
            {
                try
                {
                    if (await assertion())
                        return;
                }
                catch (Exception ex)
                {
                    lastException = ex;
                }
                
                var remainingTime = deadline - DateTime.UtcNow;
                if (remainingTime <= TimeSpan.Zero)
                    break;
                
                var delay = remainingTime < pollInterval.Value ? remainingTime : pollInterval.Value;
                await Task.Delay(delay);
            }
            
            var errorMessage = message ?? "Assertion did not become true within timeout";
            if (lastException != null)
            {
                errorMessage += $"\nLast Exception: {lastException.Message}";
            }
            throw new AssertionFailedException(errorMessage);
        }
        
        /// <summary>
        /// التحقق من قيمة مع إعادة المحاولة
        /// </summary>
        public static async Task<T> AssertEventuallyAsync<T>(
            Func<Task<T>> getValue,
            Func<T, bool> assertion,
            TimeSpan timeout,
            TimeSpan? pollInterval = null,
            string message = null)
        {
            pollInterval ??= TimeSpan.FromMilliseconds(100);
            var deadline = DateTime.UtcNow.Add(timeout);
            T lastValue = default;
            Exception lastException = null;
            
            while (DateTime.UtcNow < deadline)
            {
                try
                {
                    lastValue = await getValue();
                    if (assertion(lastValue))
                        return lastValue;
                }
                catch (Exception ex)
                {
                    lastException = ex;
                }
                
                var remainingTime = deadline - DateTime.UtcNow;
                if (remainingTime <= TimeSpan.Zero)
                    break;
                
                var delay = remainingTime < pollInterval.Value ? remainingTime : pollInterval.Value;
                await Task.Delay(delay);
            }
            
            var failureMessage = message ?? $"Value did not meet assertion within timeout. Last value: {lastValue}";
            if (lastException != null)
            {
                throw new AssertionFailedException($"{failureMessage}. Last error: {lastException.Message}");
            }
            else
            {
                throw new AssertionFailedException(failureMessage);
            }
        }
        
        /// <summary>
        /// التحقق من عدم حدوث شيء خلال فترة معينة
        /// </summary>
        public static async Task AssertNeverAsync(
            Func<Task<bool>> assertion,
            TimeSpan duration,
            TimeSpan? pollInterval = null,
            string message = null)
        {
            pollInterval ??= TimeSpan.FromMilliseconds(100);
            var deadline = DateTime.UtcNow.Add(duration);
            
            while (DateTime.UtcNow < deadline)
            {
                if (await assertion())
                {
                    var failureMessage = message ?? "Assertion became true when it should never be";
                    throw new AssertionFailedException(failureMessage);
                }
                
                var remainingTime = deadline - DateTime.UtcNow;
                if (remainingTime <= TimeSpan.Zero)
                    break;
                
                var delay = remainingTime < pollInterval.Value ? remainingTime : pollInterval.Value;
                await Task.Delay(delay);
            }
        }
        
        /// <summary>
        /// التحقق من استقرار قيمة
        /// </summary>
        public static async Task<T> AssertStableAsync<T>(
            Func<Task<T>> getValue,
            TimeSpan stabilityDuration,
            TimeSpan? pollInterval = null,
            string message = null)
        {
            pollInterval ??= TimeSpan.FromMilliseconds(100);
            var firstValue = await getValue();
            var deadline = DateTime.UtcNow.Add(stabilityDuration);
            
            while (DateTime.UtcNow < deadline)
            {
                await Task.Delay(pollInterval.Value);
                var currentValue = await getValue();
                
                if (!Equals(firstValue, currentValue))
                {
                    var failureMessage = message ?? 
                        $"Value was not stable. Changed from {firstValue} to {currentValue}";
                    throw new AssertionFailedException(failureMessage);
                }
            }
            
            return firstValue;
        }
        
        /// <summary>
        /// التحقق مع عدد محدد من المحاولات
        /// </summary>
        public static async Task AssertWithRetriesAsync(
            Func<Task> assertion,
            int maxAttempts = 3,
            TimeSpan? delayBetweenAttempts = null,
            string message = null)
        {
            delayBetweenAttempts ??= TimeSpan.FromSeconds(1);
            Exception lastException = null;
            
            for (int attempt = 1; attempt <= maxAttempts; attempt++)
            {
                try
                {
                    await assertion();
                    return;
                }
                catch (Exception ex)
                {
                    lastException = ex;
                    
                    if (attempt < maxAttempts)
                    {
                        await Task.Delay(delayBetweenAttempts.Value);
                    }
                }
            }
            
            var failureMessage = message ?? 
                $"Assertion failed after {maxAttempts} attempts. Last error: {lastException?.Message}";
            throw new AssertionFailedException(failureMessage, lastException);
        }
        
        /// <summary>
        /// التحقق من تغيير قيمة
        /// </summary>
        public static async Task<(T OldValue, T NewValue)> AssertChangesAsync<T>(
            Func<Task<T>> getValue,
            TimeSpan timeout,
            TimeSpan? pollInterval = null,
            string message = null)
        {
            pollInterval ??= TimeSpan.FromMilliseconds(100);
            var initialValue = await getValue();
            var deadline = DateTime.UtcNow.Add(timeout);
            
            while (DateTime.UtcNow < deadline)
            {
                await Task.Delay(pollInterval.Value);
                var currentValue = await getValue();
                
                if (!Equals(initialValue, currentValue))
                {
                    return (initialValue, currentValue);
                }
            }
            
            var failureMessage = message ?? 
                $"Value did not change within {timeout}. Stuck at: {initialValue}";
            throw new AssertionFailedException(failureMessage);
        }
    }
}
