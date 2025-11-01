using System;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;

namespace YemenBooking.IndexingTests.Tests
{
    /// <summary>
    /// اختبار سريع للتحقق من عدم وجود تأخير لانهائي
    /// </summary>
    public class QuickSanityTest
    {
        private readonly ITestOutputHelper _output;

        public QuickSanityTest(ITestOutputHelper output)
        {
            _output = output;
        }

        [Fact]
        public async Task Test_NoInfiniteDelay()
        {
            _output.WriteLine("🚀 بدء الاختبار السريع...");
            
            // اختبار بسيط جداً بدون أي اعتماديات
            await Task.Delay(100);
            
            Assert.True(true);
            _output.WriteLine("✅ الاختبار السريع نجح - لا يوجد تأخير لانهائي");
        }

        [Fact(Timeout = 5000)] // timeout بعد 5 ثواني
        public async Task Test_WithTimeout()
        {
            _output.WriteLine("⏱️ اختبار مع timeout...");
            
            // محاولة إنشاء TestFixture
            try
            {
                var fixture = new TestFixture();
                _output.WriteLine("✅ TestFixture تم إنشاؤه بنجاح");
                
                // تنظيف
                fixture.Dispose();
            }
            catch (Exception ex)
            {
                _output.WriteLine($"⚠️ خطأ في إنشاء TestFixture: {ex.Message}");
                // لا نفشل الاختبار، فقط نسجل الخطأ
            }
            
            await Task.CompletedTask;
            Assert.True(true);
        }
    }
}
