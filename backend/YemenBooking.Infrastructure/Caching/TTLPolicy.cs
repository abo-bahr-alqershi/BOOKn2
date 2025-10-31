using System;

namespace YemenBooking.Infrastructure.Caching
{
    public static class TTLPolicy
    {
        public static readonly TimeSpan SearchResults = TimeSpan.FromMinutes(10); // 5-15m
        public static readonly TimeSpan PriceCache = TimeSpan.FromHours(1);       // 1h
        public static readonly TimeSpan Visits = TimeSpan.FromHours(24);          // 24h
        public static readonly TimeSpan Sessions = TimeSpan.FromMinutes(30);      // 30m
        public static readonly TimeSpan OTP = TimeSpan.FromMinutes(5);            // 5m
    }
}
