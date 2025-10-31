using System;
using System.Collections.Generic;
using Bogus;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.ValueObjects;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد البيانات الأولية لكائن Booking
    /// Generates comprehensive seed data for Booking entities with diverse scenarios
    /// يحاكي سيناريوهات متعددة: حجوزات مؤكدة، معلقة، ملغاة، مكتملة، جارية، قادمة
    /// </summary>
    public class BookingSeeder : ISeeder<Booking>
    {
        public IEnumerable<Booking> SeedData()
        {
            var bookings = new List<Booking>();
            var baseDate = DateTime.UtcNow;
            var random = new Random(98765);
            
            var bookingSources = new[] { "WebApp", "MobileApp", "WalkIn", "Phone", "Email" };
            var cancellationReasons = new[]
            {
                "تغيير في خطة السفر",
                "ظروف طارئة",
                "عدم الرضا عن الخدمة",
                "إيجاد بديل أفضل",
                "مشاكل في الدفع",
                "تغيير في عدد الضيوف",
                "إلغاء بناءً على طلب المالك",
                null // بعض الحجوزات بدون سبب إلغاء
            };
            
            // توليد 100 حجز متنوع
            for (int i = 0; i < 100; i++)
            {
                BookingStatus status;
                DateTime checkIn;
                DateTime checkOut;
                DateTime bookedAt;
                DateTime? actualCheckIn = null;
                DateTime? actualCheckOut = null;
                string? cancellationReason = null;
                decimal? customerRating = null;
                string? completionNotes = null;
                
                // تحديد الحالة والسيناريو
                int scenario = i % 10;
                
                switch (scenario)
                {
                    case 0: // حجز مكتمل في الماضي مع تقييم
                        status = BookingStatus.Completed;
                        checkIn = baseDate.AddDays(-random.Next(30, 90));
                        checkOut = checkIn.AddDays(random.Next(1, 7));
                        bookedAt = checkIn.AddDays(-random.Next(7, 30));
                        actualCheckIn = checkIn.AddHours(random.Next(-2, 5));
                        actualCheckOut = checkOut.AddHours(random.Next(-3, 4));
                        customerRating = (decimal)(random.Next(35, 51) / 10.0);
                        completionNotes = "إقامة ممتازة، العميل راضٍ تماماً";
                        break;
                    
                    case 1: // حجز مؤكد قادم
                        status = BookingStatus.Confirmed;
                        checkIn = baseDate.AddDays(random.Next(5, 60));
                        checkOut = checkIn.AddDays(random.Next(2, 10));
                        bookedAt = baseDate.AddDays(-random.Next(1, 20));
                        break;
                    
                    case 2: // حجز معلق (في انتظار الدفع)
                        status = BookingStatus.Pending;
                        checkIn = baseDate.AddDays(random.Next(3, 30));
                        checkOut = checkIn.AddDays(random.Next(1, 5));
                        bookedAt = baseDate.AddDays(-random.Next(1, 7));
                        break;
                    
                    case 3: // حجز ملغي
                        status = BookingStatus.Cancelled;
                        checkIn = baseDate.AddDays(random.Next(-20, 30));
                        checkOut = checkIn.AddDays(random.Next(1, 6));
                        bookedAt = checkIn.AddDays(-random.Next(5, 25));
                        cancellationReason = cancellationReasons[random.Next(cancellationReasons.Length)];
                        break;
                    
                    case 4: // حجز جارٍ الآن (CheckedIn)
                        status = BookingStatus.CheckedIn;
                        checkIn = baseDate.AddDays(-random.Next(0, 5));
                        checkOut = baseDate.AddDays(random.Next(1, 7));
                        bookedAt = checkIn.AddDays(-random.Next(7, 40));
                        actualCheckIn = checkIn.AddHours(random.Next(-3, 6));
                        break;
                    
                    case 5: // حجز مكتمل بدون تقييم
                        status = BookingStatus.Completed;
                        checkIn = baseDate.AddDays(-random.Next(15, 60));
                        checkOut = checkIn.AddDays(random.Next(1, 8));
                        bookedAt = checkIn.AddDays(-random.Next(10, 35));
                        actualCheckIn = checkIn.AddHours(random.Next(-1, 4));
                        actualCheckOut = checkOut.AddHours(random.Next(-2, 3));
                        break;
                    
                    case 6: // حجز مرفوض/ملغي
                        status = BookingStatus.Cancelled;
                        checkIn = baseDate.AddDays(random.Next(5, 45));
                        checkOut = checkIn.AddDays(random.Next(1, 4));
                        bookedAt = baseDate.AddDays(-random.Next(1, 10));
                        cancellationReason = "تم رفضه من قبل المالك بسبب عدم التوفر";
                        break;
                    
                    case 7: // حجز مؤكد بإقامة طويلة
                        status = BookingStatus.Confirmed;
                        checkIn = baseDate.AddDays(random.Next(10, 40));
                        checkOut = checkIn.AddDays(random.Next(10, 30));
                        bookedAt = baseDate.AddDays(-random.Next(20, 50));
                        break;
                    
                    case 8: // حجز مكتمل مع تقييم ممتاز
                        status = BookingStatus.Completed;
                        checkIn = baseDate.AddDays(-random.Next(7, 45));
                        checkOut = checkIn.AddDays(random.Next(2, 6));
                        bookedAt = checkIn.AddDays(-random.Next(5, 20));
                        actualCheckIn = checkIn.AddHours(random.Next(0, 3));
                        actualCheckOut = checkOut.AddHours(random.Next(-1, 2));
                        customerRating = 5.0m;
                        completionNotes = "تجربة استثنائية، عميل VIP";
                        break;
                    
                    default: // حجز مؤكد عادي
                        status = BookingStatus.Confirmed;
                        checkIn = baseDate.AddDays(random.Next(2, 25));
                        checkOut = checkIn.AddDays(random.Next(2, 8));
                        bookedAt = baseDate.AddDays(-random.Next(3, 15));
                        break;
                }
                
                // تحديد عدد الضيوف والمبلغ
                int guestsCount = random.Next(1, 8);
                
                // تحديد العملة والمبلغ (70% YER, 30% USD)
                bool isUSD = random.Next(100) < 30;
                decimal totalAmount;
                string currency;
                
                if (isUSD)
                {
                    totalAmount = random.Next(100, 2000);
                    currency = "USD";
                }
                else
                {
                    totalAmount = random.Next(50000, 1500000);
                    currency = "YER";
                }
                
                // حساب عمولة المنصة (10%)
                decimal platformCommission = totalAmount * 0.10m;
                decimal finalAmount = totalAmount + platformCommission;
                
                // تحديد مصدر الحجز
                string bookingSource = bookingSources[random.Next(bookingSources.Length)];
                bool isWalkIn = bookingSource == "WalkIn";
                
                var booking = new Booking
                {
                    Id = Guid.NewGuid(),
                    UnitId = Guid.NewGuid(), // سيتم تحديثه في DataSeedingService
                    UserId = Guid.NewGuid(), // سيتم تحديثه في DataSeedingService
                    Status = status,
                    CheckIn = checkIn,
                    CheckOut = checkOut,
                    GuestsCount = guestsCount,
                    TotalPrice = new Money(totalAmount, currency),
                    BookedAt = bookedAt,
                    PlatformCommissionAmount = platformCommission,
                    FinalAmount = finalAmount,
                    BookingSource = bookingSource,
                    IsWalkIn = isWalkIn,
                    CancellationReason = cancellationReason,
                    ActualCheckInDate = actualCheckIn,
                    ActualCheckOutDate = actualCheckOut,
                    CustomerRating = customerRating,
                    CompletionNotes = completionNotes,
                    CreatedAt = bookedAt,
                    UpdatedAt = baseDate.AddDays(-random.Next(0, 5)),
                    IsActive = true,
                    IsDeleted = false
                };
                
                bookings.Add(booking);
            }
            
            return bookings;
        }
    }
} 