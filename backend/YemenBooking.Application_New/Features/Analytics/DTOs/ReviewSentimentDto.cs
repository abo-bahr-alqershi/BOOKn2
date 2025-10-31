using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Analytics.DTOs;

/// <summary>
/// بيانات تحليل مشاعر التقييمات
/// Review sentiment analysis data
/// </summary>
public class ReviewSentimentDto
{
    /// <summary>
    /// درجة المشاعر الإجمالية
    /// Overall sentiment score
    /// </summary>
    public double OverallSentimentScore { get; set; }

    /// <summary>
    /// الكلمات الإيجابية
    /// Positive keywords
    /// </summary>
    public IEnumerable<string> PositiveKeywords { get; set; } = new List<string>();

    /// <summary>
    /// الكلمات السلبية
    /// Negative keywords
    /// </summary>
    public IEnumerable<string> NegativeKeywords { get; set; } = new List<string>();
} 