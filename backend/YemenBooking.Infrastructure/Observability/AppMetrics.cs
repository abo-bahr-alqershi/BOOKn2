using System.Diagnostics.Metrics;

namespace YemenBooking.Infrastructure.Observability
{
    public static class AppMetrics
    {
        private static readonly Meter Meter = new("YemenBooking.Metrics", "1.0.0");

        public static readonly Counter<long> SearchRequests = Meter.CreateCounter<long>("search_requests");
        public static readonly Counter<long> SearchErrors = Meter.CreateCounter<long>("search_errors");
        public static readonly Histogram<double> SearchLatencyMs = Meter.CreateHistogram<double>("search_latency_ms");

        public static readonly Counter<long> FxCacheHits = Meter.CreateCounter<long>("fx_cache_hits");
        public static readonly Counter<long> FxCacheMisses = Meter.CreateCounter<long>("fx_cache_misses");

        public static readonly Counter<long> PriceCacheHits = Meter.CreateCounter<long>("price_cache_hits");
        public static readonly Counter<long> PriceCacheMisses = Meter.CreateCounter<long>("price_cache_misses");

        public static void RecordSearch(double elapsedMs, bool isError = false)
        {
            SearchRequests.Add(1);
            if (isError) SearchErrors.Add(1);
            SearchLatencyMs.Record(elapsedMs);
        }

        public static void RecordFxHit(bool hit)
        {
            if (hit) FxCacheHits.Add(1); else FxCacheMisses.Add(1);
        }

        public static void RecordPriceHit(bool hit)
        {
            if (hit) PriceCacheHits.Add(1); else PriceCacheMisses.Add(1);
        }
    }
}
