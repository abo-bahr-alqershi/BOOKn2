using System;
using System.Collections.Generic;

namespace YemenBooking.Core.ValueObjects;

/// <summary>
/// نتيجة تحليل مشاعر التقييم
/// Result of review sentiment analysis
/// </summary>
public class ReviewSentimentResult
{
    /// <summary>
    /// الدرجة الإجمالية للمشاعر
    /// Overall sentiment score
    /// </summary>
    public double OverallSentimentScore { get; set; }

    /// <summary>
    /// الكلمات الإيجابية المكتشفة
    /// Positive keywords detected
    /// </summary>
    public IEnumerable<string> PositiveKeywords { get; set; } = new List<string>();

    /// <summary>
    /// الكلمات السلبية المكتشفة
    /// Negative keywords detected
    /// </summary>
    public IEnumerable<string> NegativeKeywords { get; set; } = new List<string>();
} 