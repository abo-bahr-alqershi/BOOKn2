using YemenBooking.Application.Features;
// using MediatR;
// using Microsoft.Extensions.Logging;
// using System;
// using System.Threading;
// using System.Threading.Tasks;
// using YemenBooking.Core.Entities;
// using YemenBooking.Core.Interfaces;
// using YemenBooking.Application.Infrastructure.Services;
// using YemenBooking.Core.Wallets.SabaCash;

// namespace YemenBooking.Application.Features.Payments
// {
//     /// <summary>
//     /// أمر إنشاء عملية دفع جديدة عبر SabaCash
//     /// </summary>
//     public class CreateSabaCashPaymentCommand : IRequest<CreateSabaCashPaymentResponse>
//     {
//         /// <summary>
//         /// معرف الحجز المرتبط بهذه العملية
//         /// </summary>
//         public string BookingId { get; set; }

//         /// <summary>
//         /// رقم محفظة العميل (يجب أن يبدأ بـ 7)
//         /// </summary>
//         public string CustomerWallet { get; set; }

//         /// <summary>
//         /// المبلغ المطلوب دفعه بالريال اليمني
//         /// </summary>
//         public decimal Amount { get; set; }

//         /// <summary>
//         /// وصف العملية (يظهر للعميل في كشف الحساب)
//         /// </summary>
//         public string Note { get; set; }
//     }

//     /// <summary>
//     /// نتيجة أمر إنشاء عملية الدفع
//     /// </summary>
//     public class CreateSabaCashPaymentResponse
//     {
//         /// <summary>
//         /// هل نجحت العملية
//         /// </summary>
//         public bool Success { get; set; }

//         /// <summary>
//         /// معرف العملية (يستخدم للتأكيد)
//         /// </summary>
//         public string AdjustmentId { get; set; }

//         /// <summary>
//         /// رقم المعاملة الفريد
//         /// </summary>
//         public string TransactionId { get; set; }

//         /// <summary>
//         /// رسالة الخطأ في حالة الفشل
//         /// </summary>
//         public string ErrorMessage { get; set; }
//     }

//     /// <summary>
//     /// معالج أمر إنشاء عملية الدفع
//     /// </summary>
//     public class CreateSabaCashPaymentHandler : 
//         IRequestHandler<CreateSabaCashPaymentCommand, CreateSabaCashPaymentResponse>
//     {
//         private readonly ISabaCashService _sabaCashService;
//         private readonly IRepository<BookingDto> _bookingRepository;
//         private readonly IRepository<Payment> _paymentRepository;
//         private readonly ILogger<CreateSabaCashPaymentHandler> _logger;

//         public CreateSabaCashPaymentHandler(
//             ISabaCashService sabaCashService,
//             IRepository<BookingDto> bookingRepository,
//             IRepository<Payment> paymentRepository,
//             ILogger<CreateSabaCashPaymentHandler> logger)
//         {
//             _sabaCashService = sabaCashService;
//             _bookingRepository = bookingRepository;
//             _paymentRepository = paymentRepository;
//             _logger = logger;
//         }

//         public async Task<CreateSabaCashPaymentResponse> Handle(
//             CreateSabaCashPaymentCommand request, 
//             CancellationToken cancellationToken)
//         {
//             try
//             {
//                 _logger.LogInformation($"بدء معالجة طلب دفع للحجز: {request.BookingId}");

//                 // التحقق من وجود الحجز
//                 var booking = await _bookingRepository.GetByIdAsync(request.BookingId);
//                 if (booking == null)
//                 {
//                     return new CreateSabaCashPaymentResponse
//                     {
//                         Success = false,
//                         ErrorMessage = "الحجز غير موجود"
//                     };
//                 }

//                 // التحقق من حالة الحجز
//                 if (booking.Status != BookingStatus.Pending)
//                 {
//                     return new CreateSabaCashPaymentResponse
//                     {
//                         Success = false,
//                         ErrorMessage = "لا يمكن الدفع لهذا الحجز في الوقت الحالي"
//                     };
//                 }

//                 // التحقق من عدم وجود عملية دفع معلقة
//                 var pendingPayment = await _paymentRepository
//                     .GetAsync(p => p.BookingId == request.BookingId 
//                         && p.Status == Core.Enums.PaymentStatusPending);
                
//                 if (pendingPayment != null)
//                 {
//                     return new CreateSabaCashPaymentResponse
//                     {
//                         Success = false,
//                         ErrorMessage = "توجد عملية دفع معلقة لهذا الحجز"
//                     };
//                 }

//                 // إنشاء عملية الدفع في SabaCash
//                 var paymentResponse = await _sabaCashService.CreatePaymentAsync(
//                     request.CustomerWallet,
//                     request.Amount,
//                     request.Note ?? $"دفع حجز رقم {booking.BookingNumber}");

//                 // حفظ سجل الدفع في قاعدة البيانات
//                 var payment = new Payment
//                 {
//                     Id = Guid.NewGuid(),
//                     BookingId = request.BookingId,
//                     Amount = request.Amount,
//                     Currency = "YER",
//                     PaymentMethod = "SabaCash",
//                     ExternalPaymentId = paymentResponse.Adjustment.Id.ToString(),
//                     TransactionId = paymentResponse.Adjustment.TransactionId,
//                     CustomerWallet = request.CustomerWallet,
//                     Status = Core.Enums.PaymentStatusPending,
//                     CreatedAt = DateTime.UtcNow,
//                     ExpiresAt = DateTime.UtcNow.AddMinutes(5) // تنتهي صلاحية العملية بعد 5 دقائق
//                 };

//                 await _paymentRepository.AddAsync(payment);
//                 await _paymentRepository.SaveChangesAsync();

//                 _logger.LogInformation($"تم إنشاء عملية الدفع بنجاح. معرف العملية: {payment.ExternalPaymentId}");

//                 return new CreateSabaCashPaymentResponse
//                 {
//                     Success = true,
//                     AdjustmentId = paymentResponse.Adjustment.Id.ToString(),
//                     TransactionId = paymentResponse.Adjustment.TransactionId
//                 };
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في إنشاء عملية الدفع");
                
//                 return new CreateSabaCashPaymentResponse
//                 {
//                     Success = false,
//                     ErrorMessage = ex.Message
//                 };
//             }
//         }
//     }
// }

// // Features/PaymentDto/Commands/ConfirmSabaCashPayment.cs
// namespace YourApp.Features.Payments.Commands
// {
//     /// <summary>
//     /// أمر تأكيد عملية الدفع باستخدام OTP
//     /// </summary>
//     public class ConfirmSabaCashPaymentCommand : IRequest<ConfirmSabaCashPaymentResponse>
//     {
//         /// <summary>
//         /// معرف العملية المراد تأكيدها
//         /// </summary>
//         public string AdjustmentId { get; set; }

//         /// <summary>
//         /// رمز التحقق المرسل للعميل (4 أرقام)
//         /// </summary>
//         public string Otp { get; set; }

//         /// <summary>
//         /// ملاحظة إضافية (اختيارية)
//         /// </summary>
//         public string Note { get; set; }
//     }

//     /// <summary>
//     /// نتيجة أمر تأكيد عملية الدفع
//     /// </summary>
//     public class ConfirmSabaCashPaymentResponse
//     {
//         /// <summary>
//         /// هل نجحت العملية
//         /// </summary>
//         public bool Success { get; set; }

//         /// <summary>
//         /// هل اكتملت عملية الدفع
//         /// </summary>
//         public bool Completed { get; set; }

//         /// <summary>
//         /// رقم المعاملة النهائي
//         /// </summary>
//         public string TransactionId { get; set; }

//         /// <summary>
//         /// رسالة الخطأ في حالة الفشل
//         /// </summary>
//         public string ErrorMessage { get; set; }
//     }

//     /// <summary>
//     /// معالج أمر تأكيد عملية الدفع
//     /// </summary>
//     public class ConfirmSabaCashPaymentHandler : 
//         IRequestHandler<ConfirmSabaCashPaymentCommand, ConfirmSabaCashPaymentResponse>
//     {
//         private readonly ISabaCashService _sabaCashService;
//         private readonly IRepository<Payment> _paymentRepository;
//         private readonly IRepository<BookingDto> _bookingRepository;
//         private readonly ILogger<ConfirmSabaCashPaymentHandler> _logger;
//         private readonly IEmailService _emailService;

//         public ConfirmSabaCashPaymentHandler(
//             ISabaCashService sabaCashService,
//             IRepository<Payment> paymentRepository,
//             IRepository<BookingDto> bookingRepository,
//             ILogger<ConfirmSabaCashPaymentHandler> logger,
//             IEmailService emailService)
//         {
//             _sabaCashService = sabaCashService;
//             _paymentRepository = paymentRepository;
//             _bookingRepository = bookingRepository;
//             _logger = logger;
//             _emailService = emailService;
//         }

//         public async Task<ConfirmSabaCashPaymentResponse> Handle(
//             ConfirmSabaCashPaymentCommand request,
//             CancellationToken cancellationToken)
//         {
//             try
//             {
//                 _logger.LogInformation($"بدء تأكيد عملية الدفع: {request.AdjustmentId}");

//                 // البحث عن سجل الدفع في قاعدة البيانات
//                 var payment = await _paymentRepository
//                     .GetAsync(p => p.ExternalPaymentId == request.AdjustmentId);
                
//                 if (payment == null)
//                 {
//                     return new ConfirmSabaCashPaymentResponse
//                     {
//                         Success = false,
//                         ErrorMessage = "عملية الدفع غير موجودة"
//                     };
//                 }

//                 // التحقق من حالة العملية
//                 if (payment.Status != Core.Enums.PaymentStatusPending)
//                 {
//                     return new ConfirmSabaCashPaymentResponse
//                     {
//                         Success = false,
//                         ErrorMessage = payment.Status == Core.Enums.PaymentStatusCompleted 
//                             ? "تم تأكيد هذه العملية مسبقاً" 
//                             : "لا يمكن تأكيد هذه العملية"
//                     };
//                 }

//                 // التحقق من انتهاء صلاحية العملية
//                 if (payment.ExpiresAt < DateTime.UtcNow)
//                 {
//                     // تحديث حالة العملية إلى منتهية
//                     payment.Status = Core.Enums.PaymentStatusExpired;
//                     payment.UpdatedAt = DateTime.UtcNow;
//                     await _paymentRepository.UpdateAsync(payment);
//                     await _paymentRepository.SaveChangesAsync();

//                     return new ConfirmSabaCashPaymentResponse
//                     {
//                         Success = false,
//                         ErrorMessage = "انتهت صلاحية عملية الدفع. يرجى إعادة المحاولة"
//                     };
//                 }

//                 // تأكيد العملية مع SabaCash
//                 var confirmResponse = await _sabaCashService.ConfirmPaymentAsync(
//                     request.AdjustmentId,
//                     request.Otp,
//                     request.Note ?? "تأكيد عملية الدفع");

//                 // تحديث حالة الدفع
//                 if (confirmResponse.Completed)
//                 {
//                     // العملية نجحت
//                     payment.Status = Core.Enums.PaymentStatusCompleted;
//                     payment.CompletedAt = DateTime.UtcNow;
//                     payment.ConfirmationNumber = confirmResponse.TransactionId;
                    
//                     // تحديث حالة الحجز
//                     var booking = await _bookingRepository.GetByIdAsync(payment.BookingId);
//                     if (booking != null)
//                     {
//                         booking.Status = BookingStatus.Confirmed;
//                         booking.PaymentStatusDto = Core.Enums.PaymentStatusCompleted;
//                         booking.UpdatedAt = DateTime.UtcNow;
//                         await _bookingRepository.UpdateAsync(booking);
//                     }

//                     // إرسال إيميل تأكيد للعميل
//                     await SendPaymentConfirmationEmail(payment, booking);
                    
//                     _logger.LogInformation($"تم تأكيد عملية الدفع بنجاح: {payment.Id}");
//                 }
//                 else
//                 {
//                     // العملية فشلت
//                     payment.Status = Core.Enums.PaymentStatusFailed;
//                     payment.FailureReason = "فشل تأكيد العملية";
                    
//                     _logger.LogWarning($"فشل تأكيد عملية الدفع: {payment.Id}");
//                 }

//                 payment.UpdatedAt = DateTime.UtcNow;
//                 await _paymentRepository.UpdateAsync(payment);
//                 await _paymentRepository.SaveChangesAsync();

//                 return new ConfirmSabaCashPaymentResponse
//                 {
//                     Success = true,
//                     Completed = confirmResponse.Completed,
//                     TransactionId = confirmResponse.TransactionId
//                 };
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في تأكيد عملية الدفع");
                
//                 return new ConfirmSabaCashPaymentResponse
//                 {
//                     Success = false,
//                     ErrorMessage = ex.Message
//                 };
//             }
//         }

//         /// <summary>
//         /// إرسال إيميل تأكيد الدفع للعميل
//         /// </summary>
//         private async Task SendPaymentConfirmationEmail(Payment payment, BookingDto booking)
//         {
//             try
//             {
//                 if (booking?.CustomerEmail != null)
//                 {
//                     await _emailService.SendEmailAsync(new EmailMessage
//                     {
//                         To = booking.CustomerEmail,
//                         Subject = "تأكيد الدفع - حجز فندق",
//                         Body = $@"
//                             <h2>تم استلام دفعتك بنجاح</h2>
//                             <p>عزيزي {booking.CustomerName}،</p>
//                             <p>نؤكد استلام دفعتك بقيمة {payment.Amount:N0} ريال يمني.</p>
//                             <p>رقم الحجز: {booking.BookingNumber}</p>
//                             <p>رقم المعاملة: {payment.TransactionId}</p>
//                             <p>تاريخ الدفع: {payment.CompletedAt:yyyy-MM-dd HH:mm}</p>
//                             <p>شكراً لاختيارك خدماتنا.</p>
//                         "
//                     });
//                 }
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "فشل إرسال إيميل تأكيد الدفع");
//                 // لا نوقف العملية في حالة فشل الإيميل
//             }
//         }
//     }
// }

// // Features/PaymentDto/Queries/CheckSabaCashStatus.cs
// namespace YourApp.Features.Payments.Queries
// {
//     /// <summary>
//     /// استعلام للتحقق من حالة عملية الدفع
//     /// </summary>
//     public class CheckSabaCashStatusQuery : IRequest<CheckSabaCashStatusResponse>
//     {
//         /// <summary>
//         /// رقم المعاملة
//         /// </summary>
//         public string TransactionId { get; set; }
//     }

//     /// <summary>
//     /// نتيجة الاستعلام عن حالة العملية
//     /// </summary>
//     public class CheckSabaCashStatusResponse
//     {
//         /// <summary>
//         /// حالة العملية
//         /// </summary>
//         public string Status { get; set; }

//         /// <summary>
//         /// المبلغ
//         /// </summary>
//         public decimal? Amount { get; set; }

//         /// <summary>
//         /// تاريخ العملية
//         /// </summary>
//         public DateTime? TransactionDate { get; set; }

//         /// <summary>
//         /// رسالة توضيحية
//         /// </summary>
//         public string Message { get; set; }
//     }

//     /// <summary>
//     /// معالج استعلام حالة العملية
//     /// </summary>
//     public class CheckSabaCashStatusHandler : 
//         IRequestHandler<CheckSabaCashStatusQuery, CheckSabaCashStatusResponse>
//     {
//         private readonly ISabaCashService _sabaCashService;
//         private readonly ILogger<CheckSabaCashStatusHandler> _logger;

//         public CheckSabaCashStatusHandler(
//             ISabaCashService sabaCashService,
//             ILogger<CheckSabaCashStatusHandler> logger)
//         {
//             _sabaCashService = sabaCashService;
//             _logger = logger;
//         }

//         public async Task<CheckSabaCashStatusResponse> Handle(
//             CheckSabaCashStatusQuery request,
//             CancellationToken cancellationToken)
//         {
//             try
//             {
//                 // الاستعلام من SabaCash
//                 var statusResponse = await _sabaCashService.CheckPaymentStatusAsync(request.TransactionId);

//                 // تحويل حالة العملية إلى وصف واضح
//                 string statusMessage = statusResponse.StatusCode switch
//                 {
//                     "completed" => "تمت العملية بنجاح",
//                     "not-completed" => "العملية قيد المعالجة",
//                     "not-exist" => "العملية غير موجودة",
//                     _ => "حالة غير معروفة"
//                 };

//                 // تحويل التاريخ من Unix timestamp إذا كان موجوداً
//                 DateTime? transactionDate = null;
//                 if (!string.IsNullOrEmpty(statusResponse.TransactionDate) 
//                     && long.TryParse(statusResponse.TransactionDate, out var unixTime))
//                 {
//                     transactionDate = DateTimeOffset.FromUnixTimeMilliseconds(unixTime).DateTime;
//                 }

//                 // تحويل المبلغ إذا كان موجوداً
//                 decimal? amount = null;
//                 if (!string.IsNullOrEmpty(statusResponse.Amount) 
//                     && decimal.TryParse(statusResponse.Amount, out var parsedAmount))
//                 {
//                     amount = parsedAmount;
//                 }

//                 return new CheckSabaCashStatusResponse
//                 {
//                     Status = statusResponse.StatusCode,
//                     Amount = amount,
//                     TransactionDate = transactionDate,
//                     Message = statusMessage
//                 };
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في الاستعلام عن حالة العملية");
                
//                 return new CheckSabaCashStatusResponse
//                 {
//                     Status = "error",
//                     Message = "حدث خطأ في الاستعلام عن حالة العملية"
//                 };
//             }
//         }
//     }
// }

// // Features/PaymentDto/Commands/RefundSabaCashPayment.cs
// namespace YourApp.Features.Payments.Commands
// {
//     /// <summary>
//     /// أمر إرجاع مبلغ للعميل
//     /// </summary>
//     public class RefundSabaCashPaymentCommand : IRequest<RefundSabaCashPaymentResponse>
//     {
//         /// <summary>
//         /// معرف عملية الدفع الأصلية
//         /// </summary>
//         public string PaymentId { get; set; }

//         /// <summary>
//         /// المبلغ المراد إرجاعه (قد يكون جزئي)
//         /// </summary>
//         public decimal RefundAmount { get; set; }

//         /// <summary>
//         /// سبب الإرجاع
//         /// </summary>
//         public string Reason { get; set; }
//     }

//     /// <summary>
//     /// نتيجة أمر الإرجاع
//     /// </summary>
//     public class RefundSabaCashPaymentResponse
//     {
//         /// <summary>
//         /// هل نجحت العملية
//         /// </summary>
//         public bool Success { get; set; }

//         /// <summary>
//         /// معرف عملية الإرجاع
//         /// </summary>
//         public string RefundId { get; set; }

//         /// <summary>
//         /// رقم معاملة الإرجاع
//         /// </summary>
//         public string RefundTransactionId { get; set; }

//         /// <summary>
//         /// رسالة الخطأ في حالة الفشل
//         /// </summary>
//         public string ErrorMessage { get; set; }
//     }

//     /// <summary>
//     /// معالج أمر إرجاع المبلغ
//     /// </summary>
//     public class RefundSabaCashPaymentHandler : 
//         IRequestHandler<RefundSabaCashPaymentCommand, RefundSabaCashPaymentResponse>
//     {
//         private readonly ISabaCashService _sabaCashService;
//         private readonly IRepository<Payment> _paymentRepository;
//         private readonly IRepository<Refund> _refundRepository;
//         private readonly ILogger<RefundSabaCashPaymentHandler> _logger;

//         public RefundSabaCashPaymentHandler(
//             ISabaCashService sabaCashService,
//             IRepository<Payment> paymentRepository,
//             IRepository<Refund> refundRepository,
//             ILogger<RefundSabaCashPaymentHandler> logger)
//         {
//             _sabaCashService = sabaCashService;
//             _paymentRepository = paymentRepository;
//             _refundRepository = refundRepository;
//             _logger = logger;
//         }

//         public async Task<RefundSabaCashPaymentResponse> Handle(
//             RefundSabaCashPaymentCommand request,
//             CancellationToken cancellationToken)
//         {
//             try
//             {
//                 _logger.LogInformation($"بدء معالجة طلب إرجاع للدفعة: {request.PaymentId}");

//                 // البحث عن عملية الدفع الأصلية
//                 var payment = await _paymentRepository.GetByIdAsync(request.PaymentId);
//                 if (payment == null)
//                 {
//                     return new RefundSabaCashPaymentResponse
//                     {
//                         Success = false,
//                         ErrorMessage = "عملية الدفع غير موجودة"
//                     };
//                 }

//                 // التحقق من حالة الدفع
//                 if (payment.Status != Core.Enums.PaymentStatusCompleted)
//                 {
//                     return new RefundSabaCashPaymentResponse
//                     {
//                         Success = false,
//                         ErrorMessage = "لا يمكن إرجاع مبلغ لعملية دفع غير مكتملة"
//                     };
//                 }

//                 // التحقق من المبلغ المطلوب إرجاعه
//                 var totalRefunded = await _refundRepository
//                     .SumAsync(r => r.PaymentId == payment.Id 
//                         && r.Status == RefundStatus.Completed, 
//                         r => r.Amount);

//                 var remainingAmount = payment.Amount - totalRefunded;
//                 if (request.RefundAmount > remainingAmount)
//                 {
//                     return new RefundSabaCashPaymentResponse
//                     {
//                         Success = false,
//                         ErrorMessage = $"المبلغ المطلوب إرجاعه أكبر من المتبقي ({remainingAmount:N0} ريال)"
//                     };
//                 }

//                 // إنشاء عملية الإرجاع في SabaCash
//                 var refundResponse = await _sabaCashService.RefundPaymentAsync(
//                     payment.ExternalPaymentId,
//                     payment.CustomerWallet,
//                     request.RefundAmount,
//                     payment.TransactionId,
//                     request.Reason ?? "إرجاع مبلغ");

//                 // حفظ سجل الإرجاع
//                 var refund = new Refund
//                 {
//                     Id = Guid.NewGuid().ToString(),
//                     PaymentId = payment.Id,
//                     Amount = request.RefundAmount,
//                     Reason = request.Reason,
//                     ExternalRefundId = refundResponse.Adjustment.Id.ToString(),
//                     TransactionId = refundResponse.Adjustment.TransactionId,
//                     Status = RefundStatus.Pending,
//                     CreatedAt = DateTime.UtcNow
//                 };

//                 await _refundRepository.AddAsync(refund);

//                 // تأكيد عملية الإرجاع تلقائياً (لا تحتاج OTP)
//                 refund.Status = RefundStatus.Completed;
//                 refund.CompletedAt = DateTime.UtcNow;

//                 await _refundRepository.SaveChangesAsync();

//                 _logger.LogInformation($"تمت عملية الإرجاع بنجاح. معرف الإرجاع: {refund.Id}");

//                 return new RefundSabaCashPaymentResponse
//                 {
//                     Success = true,
//                     RefundId = refund.Id,
//                     RefundTransactionId = refund.TransactionId
//                 };
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في معالجة عملية الإرجاع");
                
//                 return new RefundSabaCashPaymentResponse
//                 {
//                     Success = false,
//                     ErrorMessage = ex.Message
//                 };
//             }
//         }
//     }
// }