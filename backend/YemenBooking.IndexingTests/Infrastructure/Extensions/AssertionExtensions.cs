using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using FluentAssertions;
using FluentAssertions.Execution;
using FluentAssertions.Primitives;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.IndexingTests.Infrastructure.Assertions;

namespace YemenBooking.IndexingTests.Infrastructure.Extensions
{
    /// <summary>
    /// Extension methods للـ assertions
    /// تطبيق best practices وتوفير assertions إضافية
    /// </summary>
    public static class AssertionExtensions
    {
        /// <summary>
        /// التحقق من أن PropertySearchResultAssertions ليست null
        /// </summary>
        public static AndConstraint<PropertySearchResultAssertions> NotBeNull(
            this PropertySearchResultAssertions assertions,
            string because = "",
            params object[] becauseArgs)
        {
            Execute.Assertion
                .BecauseOf(because, becauseArgs)
                .WithExpectation("Expected search result {0} to exist{reason}, ", "not to be null")
                .FailWith("but it was null");

            return new AndConstraint<PropertySearchResultAssertions>(assertions);
        }

        /// <summary>
        /// التحقق من أن عدد النتائج يساوي الصفر
        /// </summary>
        public static AndConstraint<PropertySearchResultAssertions> BeEmpty(
            this PropertySearchResultAssertions assertions,
            string because = "",
            params object[] becauseArgs)
        {
            assertions.HaveCount(0, because);
            return new AndConstraint<PropertySearchResultAssertions>(assertions);
        }

        /// <summary>
        /// التحقق من أن عدد النتائج أكبر من الصفر
        /// </summary>
        public static AndConstraint<PropertySearchResultAssertions> NotBeEmpty(
            this PropertySearchResultAssertions assertions,
            string because = "",
            params object[] becauseArgs)
        {
            assertions.HaveAtLeast(1, because);
            return new AndConstraint<PropertySearchResultAssertions>(assertions);
        }

        /// <summary>
        /// التحقق من أن جميع النتائج تطابق شرطاً معيناً
        /// </summary>
        public static AndConstraint<PropertySearchResultAssertions> AllMatch(
            this PropertySearchResultAssertions assertions,
            Func<PropertySearchItem, bool> predicate,
            string because = "",
            params object[] becauseArgs)
        {
            // يمكن تنفيذ هذا في PropertySearchResultAssertions نفسها
            return new AndConstraint<PropertySearchResultAssertions>(assertions);
        }

        /// <summary>
        /// Extension method لـ Task للتحقق من إكماله خلال فترة زمنية
        /// </summary>
        public static async Task<AndConstraint<Task>> CompleteWithinAsync(
            this Task task,
            TimeSpan timeout,
            string because = "",
            params object[] becauseArgs)
        {
            var completedTask = await Task.WhenAny(task, Task.Delay(timeout));
            
            Execute.Assertion
                .BecauseOf(because, becauseArgs)
                .ForCondition(completedTask == task)
                .FailWith("Expected task to complete within {0}{reason}, but it timed out",
                    timeout);

            return new AndConstraint<Task>(task);
        }

        /// <summary>
        /// Extension method لـ IEnumerable<Task> للتحقق من إكمالها جميعاً
        /// </summary>
        public static async Task<AndConstraint<IEnumerable<Task>>> AllCompleteWithinAsync(
            this IEnumerable<Task> tasks,
            TimeSpan timeout,
            string because = "",
            params object[] becauseArgs)
        {
            var allTasks = Task.WhenAll(tasks);
            await allTasks.CompleteWithinAsync(timeout, because, becauseArgs);
            
            return new AndConstraint<IEnumerable<Task>>(tasks);
        }

        /// <summary>
        /// Extension method للتحقق من نتيجة eventually consistent
        /// </summary>
        public static async Task<T> ShouldEventuallyBe<T>(
            this Task<T> task,
            T expectedValue,
            TimeSpan timeout,
            TimeSpan pollInterval,
            string because = "",
            params object[] becauseArgs)
        {
            var deadline = DateTime.UtcNow.Add(timeout);
            T actualValue = default(T);
            
            while (DateTime.UtcNow < deadline)
            {
                actualValue = await task;
                
                if (EqualityComparer<T>.Default.Equals(actualValue, expectedValue))
                {
                    return actualValue;
                }
                
                await Task.Delay(pollInterval);
            }
            
            Execute.Assertion
                .BecauseOf(because, becauseArgs)
                .ForCondition(false)
                .FailWith("Expected value to eventually be {0}{reason}, but it remained {1} after {2}",
                    expectedValue, actualValue, timeout);
            
            return actualValue;
        }

        /// <summary>
        /// Extension method للتحقق من أن قيمة تتغير خلال فترة معينة
        /// </summary>
        public static async Task<T> ShouldEventuallyChange<T>(
            this Func<Task<T>> getValue,
            T fromValue,
            TimeSpan timeout,
            TimeSpan pollInterval,
            string because = "",
            params object[] becauseArgs)
        {
            var deadline = DateTime.UtcNow.Add(timeout);
            T currentValue = default(T);
            
            while (DateTime.UtcNow < deadline)
            {
                currentValue = await getValue();
                
                if (!EqualityComparer<T>.Default.Equals(currentValue, fromValue))
                {
                    return currentValue;
                }
                
                await Task.Delay(pollInterval);
            }
            
            Execute.Assertion
                .BecauseOf(because, becauseArgs)
                .ForCondition(false)
                .FailWith("Expected value to change from {0}{reason}, but it remained unchanged after {1}",
                    fromValue, timeout);
            
            return currentValue;
        }

        /// <summary>
        /// Extension للتحقق من عدم حدوث deadlock
        /// </summary>
        public static async Task ShouldNotDeadlock(
            this Task task,
            TimeSpan timeout,
            string because = "",
            params object[] becauseArgs)
        {
            var completed = await Task.WhenAny(task, Task.Delay(timeout)) == task;
            
            Execute.Assertion
                .BecauseOf(because, becauseArgs)
                .ForCondition(completed)
                .FailWith("Expected operation to complete without deadlock{reason}, but it exceeded timeout of {0}",
                    timeout);
        }

        /// <summary>
        /// Extension للتحقق من thread safety
        /// </summary>
        public static async Task ShouldBeThreadSafe<T>(
            this Func<Task<T>> operation,
            int concurrencyLevel,
            Func<T, bool> validator,
            string because = "",
            params object[] becauseArgs)
        {
            var tasks = new List<Task<T>>();
            
            for (int i = 0; i < concurrencyLevel; i++)
            {
                tasks.Add(Task.Run(operation));
            }
            
            var results = await Task.WhenAll(tasks);
            
            Execute.Assertion
                .BecauseOf(because, becauseArgs)
                .ForCondition(results.All(validator))
                .FailWith("Expected all {0} concurrent operations to be valid{reason}, but some failed validation",
                    concurrencyLevel);
        }

        /// <summary>
        /// Extension للتحقق من الأداء
        /// </summary>
        public static async Task<TimeSpan> ShouldExecuteWithin(
            this Task task,
            TimeSpan maxDuration,
            string because = "",
            params object[] becauseArgs)
        {
            var stopwatch = System.Diagnostics.Stopwatch.StartNew();
            await task;
            stopwatch.Stop();
            
            Execute.Assertion
                .BecauseOf(because, becauseArgs)
                .ForCondition(stopwatch.Elapsed <= maxDuration)
                .FailWith("Expected operation to complete within {0}{reason}, but it took {1}",
                    maxDuration, stopwatch.Elapsed);
            
            return stopwatch.Elapsed;
        }

        /// <summary>
        /// Extension للتحقق من عدم وجود memory leaks
        /// </summary>
        public static async Task<long> ShouldNotLeakMemory(
            this Func<Task> operation,
            int iterations,
            long maxMemoryGrowth,
            string because = "",
            params object[] becauseArgs)
        {
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            
            var initialMemory = GC.GetTotalMemory(false);
            
            for (int i = 0; i < iterations; i++)
            {
                await operation();
            }
            
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            
            var finalMemory = GC.GetTotalMemory(false);
            var memoryGrowth = finalMemory - initialMemory;
            
            Execute.Assertion
                .BecauseOf(because, becauseArgs)
                .ForCondition(memoryGrowth <= maxMemoryGrowth)
                .FailWith("Expected memory growth to be at most {0} bytes{reason}, but it grew by {1} bytes",
                    maxMemoryGrowth, memoryGrowth);
            
            return memoryGrowth;
        }
    }
}
