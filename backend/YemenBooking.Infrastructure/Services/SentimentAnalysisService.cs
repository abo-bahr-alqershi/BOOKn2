using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.ValueObjects;
using System.Collections.Generic;
using System.Linq;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة تحليل المشاعر
    /// Sentiment analysis service implementation
    /// </summary>
    public class SentimentAnalysisService : ISentimentAnalysisService
    {
        private readonly ILogger<SentimentAnalysisService> _logger;

        private static readonly string[] PositiveWords = new[] { "جيد", "ممتاز", "رائع", "مذهل", "سعيد", "محبوب", "مريح", "جميل" };
        private static readonly string[] NegativeWords = new[] { "سيء", "فظيع", "تعيس", "حزين", "قليل الجودة", "مشاكل", "مزعج", "خائب" };

        public SentimentAnalysisService(ILogger<SentimentAnalysisService> logger)
        {
            _logger = logger;
        }

        /// <inheritdoc />
        public Task<ReviewSentimentResult> AnalyzeSentimentAsync(string text)
        {
            _logger.LogInformation("بدء تحليل المشاعر للنص: {Text}", text);
            var words = text
                .Split(new[] { ' ', '\t', '\n', '\r', '.', ',', '!', '?' }, System.StringSplitOptions.RemoveEmptyEntries)
                .Select(w => w.Trim().ToLowerInvariant());

            var positiveKeywords = words.Where(w => PositiveWords.Contains(w)).Distinct().ToList();
            var negativeKeywords = words.Where(w => NegativeWords.Contains(w)).Distinct().ToList();

            double score = 0;
            if (positiveKeywords.Count + negativeKeywords.Count > 0)
                score = (double)(positiveKeywords.Count - negativeKeywords.Count) / (positiveKeywords.Count + negativeKeywords.Count);

            var result = new ReviewSentimentResult
            {
                OverallSentimentScore = Math.Round(score, 2),
                PositiveKeywords = positiveKeywords,
                NegativeKeywords = negativeKeywords
            };

            return Task.FromResult(result);
        }
    }
} 