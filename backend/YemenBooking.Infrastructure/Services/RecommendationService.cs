using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة التوصيات
    /// Recommendation service implementation
    /// </summary>
    public class RecommendationService : IRecommendationService
    {
        private readonly ILogger<RecommendationService> _logger;
        private readonly YemenBookingDbContext _dbContext;

        public RecommendationService(ILogger<RecommendationService> logger, YemenBookingDbContext dbContext)
        {
            _logger = logger;
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<Property>> GetRecommendedPropertiesAsync(Guid userId, int count = 10, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على توصيات لكيانات للمستخدم: {UserId}", userId);
            var properties = await _dbContext.Properties
                .Where(p => p.IsApproved)
                .OrderByDescending(p => p.ViewCount)
                .Take(count)
                .ToListAsync(cancellationToken);
            return properties;
        }

        public async Task<object> AnalyzeUserPreferencesAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تحليل تفضيلات المستخدم: {UserId}", userId);
            var typeCounts = await _dbContext.Bookings
                .Where(b => b.UserId == userId)
                .Include(b => b.Unit).ThenInclude(u => u.Property)
                .Select(b => b.Unit.Property.TypeId)
                .ToListAsync(cancellationToken);
            var preferences = typeCounts
                .GroupBy(id => id)
                .ToDictionary(g => g.Key, g => g.Count());
            return preferences;
        }

        public async Task<bool> UpdateRecommendationModelAsync(Guid userId, Dictionary<string, object> userActivity, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تحديث نموذج التوصيات للمستخدم: {UserId}", userId);
            // منطق تحديث النموذج (وهمي)
            await Task.CompletedTask;
            return true;
        }

        public async Task<IEnumerable<Property>> GetSimilarPropertiesAsync(Guid propertyId, int count = 5, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على كيانات مشابهة للمعرف: {PropertyId}", propertyId);
            var prop = await _dbContext.Properties.FindAsync(new object[]{propertyId}, cancellationToken);
            if (prop == null) return Enumerable.Empty<Property>();
            var similar = await _dbContext.Properties
                .Where(p => p.TypeId == prop.TypeId && p.Id != propertyId)
                .Take(count)
                .ToListAsync(cancellationToken);
            return similar;
        }

        public async Task<IEnumerable<Property>> GetLocationBasedRecommendationsAsync(double latitude, double longitude, int count = 10, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على توصيات بناءً على الموقع: {Latitude},{Longitude}", latitude, longitude);
            var recs = await _dbContext.Properties
                .Where(p => p.IsApproved)
                .Select(p => new { Prop = p, Dist = (Math.Abs((double)p.Latitude - latitude) + Math.Abs((double)p.Longitude - longitude)) })
                .OrderBy(x => x.Dist)
                .Take(count)
                .Select(x => x.Prop)
                .ToListAsync(cancellationToken);
            return recs;
        }

        public async Task<IEnumerable<Property>> GetHistoryBasedRecommendationsAsync(Guid userId, int count = 10, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على توصيات بناءً على التاريخ للمستخدم: {UserId}", userId);
            // استخدام التوصيات العامة للمستخدم
            return await GetRecommendedPropertiesAsync(userId, count, cancellationToken);
        }

        public Task<decimal> CalculateCompatibilityScoreAsync(Guid userId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("حساب درجة التوافق للمستخدم: {UserId} والكيان: {PropertyId}", userId, propertyId);
            // حساب وهمي للدرجة
            var score = (decimal)Random.Shared.NextDouble();
            return Task.FromResult(decimal.Round(score, 2));
        }

        public async Task<bool> TrainRecommendationModelAsync(CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("بدء تدريب نموذج التوصيات");
            // منطق التدريب الوهمي
            await Task.Delay(500, cancellationToken);
            return true;
        }
    }
} 