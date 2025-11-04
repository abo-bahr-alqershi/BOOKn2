using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FluentAssertions;
using FluentAssertions.Execution;
using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.IndexingTests.Infrastructure.Assertions
{
    /// <summary>
    /// Assertions مخصصة للاختبارات
    /// </summary>
    public static class CustomAssertions
    {
        /// <summary>
        /// التحقق من نتائج البحث
        /// </summary>
        public static PropertySearchResultAssertions Should(this PropertySearchResult result)
        {
            return new PropertySearchResultAssertions(result);
        }
        
        /// <summary>
        /// التحقق من عنصر البحث
        /// </summary>
        public static PropertySearchItemAssertions Should(this PropertySearchItem item)
        {
            return new PropertySearchItemAssertions(item);
        }
    }
    
    /// <summary>
    /// Assertions لنتائج البحث
    /// </summary>
    public class PropertySearchResultAssertions
    {
        private readonly PropertySearchResult _result;
        public PropertySearchResult Subject => _result;
        
        public PropertySearchResultAssertions(PropertySearchResult result)
        {
            _result = result;
        }
        
        /// <summary>
        /// التحقق من أن النتيجة ليست null
        /// </summary>
        public PropertySearchResultAssertions NotBeNull(string because = "")
        {
            Execute.Assertion
                .ForCondition(_result != null)
                .FailWith("Expected search result not to be null{{reason}}, but it was.", because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من عدد النتائج
        /// </summary>
        public PropertySearchResultAssertions HaveCount(int expectedCount, string because = "")
        {
            Execute.Assertion
                .ForCondition(_result != null)
                .FailWith("Expected search result to exist, but it was null")
                .Then
                .ForCondition(_result.TotalCount == expectedCount)
                .FailWith($"Expected search result to have {{0}} items{{reason}}, but found {{1}}",
                    expectedCount, _result.TotalCount, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من وجود نتائج على الأقل
        /// </summary>
        public PropertySearchResultAssertions HaveAtLeast(int minCount, string because = "")
        {
            Execute.Assertion
                .ForCondition(_result != null)
                .FailWith("Expected search result to exist, but it was null")
                .Then
                .ForCondition(_result.TotalCount >= minCount)
                .FailWith($"Expected search result to have at least {{0}} items{{reason}}, but found {{1}}",
                    minCount, _result.TotalCount, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من عدم تجاوز حد معين
        /// </summary>
        public PropertySearchResultAssertions HaveAtMost(int maxCount, string because = "")
        {
            Execute.Assertion
                .ForCondition(_result != null)
                .FailWith("Expected search result to exist, but it was null")
                .Then
                .ForCondition(_result.TotalCount <= maxCount)
                .FailWith($"Expected search result to have at most {{0}} items{{reason}}, but found {{1}}",
                    maxCount, _result.TotalCount, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من أن جميع النتائج في مدينة معينة
        /// </summary>
        public PropertySearchResultAssertions AllBeInCity(string city, string because = "")
        {
            Execute.Assertion
                .ForCondition(_result?.Properties != null)
                .FailWith("Expected search result properties to exist, but they were null")
                .Then
                .ForCondition(_result.Properties.All(p => 
                    string.Equals(p.City, city, StringComparison.OrdinalIgnoreCase)))
                .FailWith($"Expected all properties to be in city '{{0}}'{{reason}}, but found properties in other cities",
                    city, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من أن جميع النتائج من نوع معين
        /// </summary>
        public PropertySearchResultAssertions AllBeOfType(string propertyType, string because = "")
        {
            Execute.Assertion
                .ForCondition(_result?.Properties != null)
                .FailWith("Expected search result properties to exist, but they were null")
                .Then
                .ForCondition(_result.Properties.All(p => 
                    string.Equals(p.PropertyType, propertyType, StringComparison.OrdinalIgnoreCase)))
                .FailWith($"Expected all properties to be of type '{{0}}'{{reason}}, but found other types",
                    propertyType, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من نطاق الأسعار
        /// </summary>
        public PropertySearchResultAssertions HavePricesInRange(decimal min, decimal max, string because = "")
        {
            Execute.Assertion
                .ForCondition(_result?.Properties != null)
                .FailWith("Expected search result properties to exist, but they were null")
                .Then
                .ForCondition(_result.Properties.All(p => p.MinPrice >= min && p.MinPrice <= max))
                .FailWith($"Expected all properties to have prices between {{0}} and {{1}}{{reason}}, but found prices outside this range",
                    min, max, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من الترتيب حسب السعر
        /// </summary>
        public PropertySearchResultAssertions BeSortedByPrice(bool ascending = true, string because = "")
        {
            if (_result?.Properties == null || _result.Properties.Count <= 1)
                return this;
            
            var prices = _result.Properties.Select(p => p.MinPrice).ToList();
            var expectedPrices = ascending ? prices.OrderBy(p => p).ToList() : prices.OrderByDescending(p => p).ToList();
            
            Execute.Assertion
                .ForCondition(prices.SequenceEqual(expectedPrices))
                .FailWith($"Expected properties to be sorted by price {{0}}{{reason}}, but they were not",
                    ascending ? "ascending" : "descending", because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من الترتيب حسب التقييم
        /// </summary>
        public PropertySearchResultAssertions BeSortedByRating(bool descending = true, string because = "")
        {
            if (_result?.Properties == null || _result.Properties.Count <= 1)
                return this;
            
            var ratings = _result.Properties.Select(p => p.AverageRating).ToList();
            var expectedRatings = descending ? ratings.OrderByDescending(r => r).ToList() : ratings.OrderBy(r => r).ToList();
            
            Execute.Assertion
                .ForCondition(ratings.SequenceEqual(expectedRatings))
                .FailWith($"Expected properties to be sorted by rating {{0}}{{reason}}, but they were not",
                    descending ? "descending" : "ascending", because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من وجود عقار معين
        /// </summary>
        public PropertySearchResultAssertions ContainProperty(Guid propertyId, string because = "")
        {
            Execute.Assertion
                .ForCondition(_result?.Properties != null)
                .FailWith("Expected search result properties to exist, but they were null")
                .Then
                .ForCondition(_result.Properties.Any(p => p.Id == propertyId.ToString()))
                .FailWith($"Expected search results to contain property with ID '{{0}}'{{reason}}, but it was not found",
                    propertyId, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من وجود عقار معين بواسطة string ID
        /// </summary>
        public PropertySearchResultAssertions ContainProperty(string propertyId, string because = "")
        {
            Execute.Assertion
                .ForCondition(_result?.Properties != null)
                .FailWith("Expected search result properties to exist, but they were null")
                .Then
                .ForCondition(_result.Properties.Any(p => p.Id == propertyId))
                .FailWith($"Expected search results to contain property with ID '{{0}}'{{reason}}, but it was not found",
                    propertyId, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من عدم وجود عقار معين
        /// </summary>
        public PropertySearchResultAssertions NotContainProperty(Guid propertyId, string because = "")
        {
            Execute.Assertion
                .ForCondition(_result?.Properties != null)
                .FailWith("Expected search result properties to exist, but they were null")
                .Then
                .ForCondition(!_result.Properties.Any(p => p.Id == propertyId.ToString()))
                .FailWith($"Expected search results not to contain property with ID '{{0}}'{{reason}}, but it was found",
                    propertyId, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من عدم وجود عقار معين بواسطة string ID
        /// </summary>
        public PropertySearchResultAssertions NotContainProperty(string propertyId, string because = "")
        {
            Execute.Assertion
                .ForCondition(_result?.Properties != null)
                .FailWith("Expected search result properties to exist, but they were null")
                .Then
                .ForCondition(!_result.Properties.Any(p => p.Id == propertyId))
                .FailWith($"Expected search results not to contain property with ID '{{0}}'{{reason}}, but it was found",
                    propertyId, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من الصفحة الحالية
        /// </summary>
        public PropertySearchResultAssertions BeOnPage(int pageNumber, string because = "")
        {
            Execute.Assertion
                .ForCondition(_result != null)
                .FailWith("Expected search result to exist, but it was null")
                .Then
                .ForCondition(_result.PageNumber == pageNumber)
                .FailWith($"Expected search result to be on page {{0}}{{reason}}, but was on page {{1}}",
                    pageNumber, _result.PageNumber, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من حجم الصفحة
        /// </summary>
        public PropertySearchResultAssertions HavePageSize(int pageSize, string because = "")
        {
            Execute.Assertion
                .ForCondition(_result != null)
                .FailWith("Expected search result to exist, but it was null")
                .Then
                .ForCondition(_result.PageSize == pageSize)
                .FailWith($"Expected search result to have page size {{0}}{{reason}}, but had {{1}}",
                    pageSize, _result.PageSize, because);
            
            return this;
        }
    }
    
    /// <summary>
    /// Assertions لعنصر البحث
    /// </summary>
    public class PropertySearchItemAssertions
    {
        private readonly PropertySearchItem _item;
        
        public PropertySearchItemAssertions(PropertySearchItem item)
        {
            _item = item;
        }
        
        /// <summary>
        /// التحقق من الاسم
        /// </summary>
        public PropertySearchItemAssertions HaveName(string expectedName, string because = "")
        {
            Execute.Assertion
                .ForCondition(_item != null)
                .FailWith("Expected property item to exist, but it was null")
                .Then
                .ForCondition(string.Equals(_item.Name, expectedName, StringComparison.OrdinalIgnoreCase))
                .FailWith($"Expected property to have name '{{0}}'{{reason}}, but found '{{1}}'",
                    expectedName, _item.Name, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من المدينة
        /// </summary>
        public PropertySearchItemAssertions BeInCity(string city, string because = "")
        {
            Execute.Assertion
                .ForCondition(_item != null)
                .FailWith("Expected property item to exist, but it was null")
                .Then
                .ForCondition(string.Equals(_item.City, city, StringComparison.OrdinalIgnoreCase))
                .FailWith($"Expected property to be in city '{{0}}'{{reason}}, but found '{{1}}'",
                    city, _item.City, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من السعر
        /// </summary>
        public PropertySearchItemAssertions HavePrice(decimal expectedPrice, string because = "")
        {
            Execute.Assertion
                .ForCondition(_item != null)
                .FailWith("Expected property item to exist, but it was null")
                .Then
                .ForCondition(_item.MinPrice == expectedPrice)
                .FailWith($"Expected property to have price {{0}}{{reason}}, but found {{1}}",
                    expectedPrice, _item.MinPrice, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من التقييم
        /// </summary>
        public PropertySearchItemAssertions HaveRating(decimal expectedRating, string because = "")
        {
            Execute.Assertion
                .ForCondition(_item != null)
                .FailWith("Expected property item to exist, but it was null")
                .Then
                .ForCondition(_item.AverageRating == expectedRating)
                .FailWith($"Expected property to have rating {{0}}{{reason}}, but found {{1}}",
                    expectedRating, _item.AverageRating, because);
            
            return this;
        }
        
        /// <summary>
        /// التحقق من السعة
        /// </summary>
        public PropertySearchItemAssertions HaveCapacity(int expectedCapacity, string because = "")
        {
            Execute.Assertion
                .ForCondition(_item != null)
                .FailWith("Expected property item to exist, but it was null")
                .Then
                .ForCondition(_item.MaxCapacity == expectedCapacity)
                .FailWith($"Expected property to have capacity {{0}}{{reason}}, but found {{1}}",
                    expectedCapacity, _item.MaxCapacity, because);
            
            return this;
        }
    }
}
