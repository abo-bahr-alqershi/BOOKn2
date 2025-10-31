// // Controllers/PaymentController.cs
// using MediatR;
// using Microsoft.AspNetCore.Mvc;
// using Microsoft.AspNetCore.Authorization;
// using System.Threading.Tasks;

// namespace YourApp.Controllers
// {
//     /// <summary>
//     /// واجهة برمجية للتعامل مع عمليات الدفع
//     /// </summary>
//     [ApiController]
//     [Route("api/[controller]")]
//     [Authorize] // يتطلب مصادقة المستخدم
//     public class PaymentController : ControllerBase
//     {
//         private readonly IMediator _mediator;
//         private readonly ILogger<PaymentController> _logger;

//         public PaymentController(
//             IMediator mediator,
//             ILogger<PaymentController> logger)
//         {
//             _mediator = mediator;
//             _logger = logger;
//         }

//         /// <summary>
//         /// إنشاء عملية دفع جديدة عبر YottaPay
//         /// </summary>
//         /// <param name="command">بيانات عملية الدفع</param>
//         /// <returns>معرف العملية ورقم المعاملة</returns>
//         /// <response code="200">تم إنشاء العملية بنجاح</response>
//         /// <response code="400">بيانات غير صحيحة أو رصيد غير كافي</response>
//         [HttpPost("yottapay/create")]
//         [ProducesResponseType(typeof(CreateYottaPayPaymentResponse), 200)]
//         [ProducesResponseType(typeof(ErrorResponse), 400)]
//         public async Task<IActionResult> CreateYottaPayPayment(
//             [FromBody] CreateYottaPayPaymentCommand command)
//         {
//             _logger.LogInformation($"طلب إنشاء عملية دفع للحجز: {command.BookingId}");

//             // التحقق من صحة البيانات
//             if (!ModelState.IsValid)
//             {
//                 return BadRequest(new ErrorResponse 
//                 { 
//                     Message = "البيانات المدخلة غير صحيحة",
//                     Details = ModelState.Values
//                         .SelectMany(v => v.Errors)
//                         .Select(e => e.ErrorMessage)
//                         .ToList()
//                 });
//             }

//             var result = await _mediator.Send(command);
            
//             if (!result.Success)
//             {
//                 _logger.LogWarning($"فشل إنشاء عملية الدفع: {result.ErrorMessage}");
//                 return BadRequest(new ErrorResponse { Message = result.ErrorMessage });
//             }
            
//             return Ok(new
//             {
//                 success = true,
//                 adjustmentId = result.AdjustmentId,
//                 transactionId = result.TransactionId,
//                 message = "تم إنشاء عملية الدفع بنجاح. يرجى إدخال رمز التحقق المرسل إلى محفظتك"
//             });
//         }

//         /// <summary>
//         /// تأكيد عملية الدفع باستخدام رمز التحقق OTP
//         /// </summary>
//         /// <param name="command">بيانات التأكيد</param>
//         /// <returns>حالة العملية</returns>
//         /// <response code="200">تم تأكيد العملية</response>
//         /// <response code="400">رمز تحقق خاطئ أو انتهت صلاحية العملية</response>
//         [HttpPost("yottapay/confirm")]
//         [ProducesResponseType(typeof(ConfirmYottaPayPaymentResponse), 200)]
//         [ProducesResponseType(typeof(ErrorResponse), 400)]
//         public async Task<IActionResult> ConfirmYottaPayPayment(
//             [FromBody] ConfirmYottaPayPaymentCommand command)
//         {
//             _logger.LogInformation($"طلب تأكيد عملية الدفع: {command.AdjustmentId}");

//             // التحقق من طول رمز التحقق
//             if (string.IsNullOrEmpty(command.Otp) || command.Otp.Length != 4)
//             {
//                 return BadRequest(new ErrorResponse 
//                 { 
//                     Message = "رمز التحقق يجب أن يتكون من 4 أرقام" 
//                 });
//             }

//             var result = await _mediator.Send(command);
            
//             if (!result.Success)
//             {
//                 _logger.LogWarning($"فشل تأكيد عملية الدفع: {result.ErrorMessage}");
//                 return BadRequest(new ErrorResponse { Message = result.ErrorMessage });
//             }
            
//             return Ok(new
//             {
//                 success = true,
//                 completed = result.Completed,
//                 transactionId = result.TransactionId,
//                 message = result.Completed 
//                     ? "تم الدفع بنجاح" 
//                     : "فشلت عملية الدفع"
//             });
//         }

//         /// <summary>
//         /// الاستعلام عن حالة عملية دفع
//         /// </summary>
//         /// <param name="transactionId">رقم المعاملة</param>
//         /// <returns>تفاصيل حالة العملية</returns>
//         /// <response code="200">تم الاستعلام بنجاح</response>
//         /// <response code="404">العملية غير موجودة</response>
//         [HttpGet("yottapay/status/{transactionId}")]
//         [ProducesResponseType(typeof(CheckYottaPayStatusResponse), 200)]
//         public async Task<IActionResult> CheckPaymentStatus(string transactionId)
//         {
//             _logger.LogInformation($"استعلام عن حالة المعاملة: {transactionId}");

//             var query = new CheckYottaPayStatusQuery { TransactionId = transactionId };
//             var result = await _mediator.Send(query);
            
//             return Ok(result);
//         }

//         /// <summary>
//         /// إرجاع مبلغ للعميل
//         /// </summary>
//         /// <param name="command">بيانات الإرجاع</param>
//         /// <returns>تفاصيل عملية الإرجاع</returns>
//         /// <response code="200">تم الإرجاع بنجاح</response>
//         /// <response code="400">لا يمكن إرجاع المبلغ</response>
//         [HttpPost("yottapay/refund")]
//         [Authorize(Roles = "Admin,Manager")] // يحتاج صلاحيات إدارية
//         [ProducesResponseType(typeof(RefundYottaPayPaymentResponse), 200)]
//         [ProducesResponseType(typeof(ErrorResponse), 400)]
//         public async Task<IActionResult> RefundPayment(
//             [FromBody] RefundYottaPayPaymentCommand command)
//         {
//             _logger.LogInformation($"طلب إرجاع مبلغ للدفعة: {command.PaymentId}");

//             if (command.RefundAmount <= 0)
//             {
//                 return BadRequest(new ErrorResponse 
//                 { 
//                     Message = "مبلغ الإرجاع يجب أن يكون أكبر من صفر" 
//                 });
//             }

//             var result = await _mediator.Send(command);
            
//             if (!result.Success)
//             {
//                 _logger.LogWarning($"فشل إرجاع المبلغ: {result.ErrorMessage}");
//                 return BadRequest(new ErrorResponse { Message = result.ErrorMessage });
//             }
            
//             return Ok(new
//             {
//                 success = true,
//                 refundId = result.RefundId,
//                 transactionId = result.RefundTransactionId,
//                 message = "تمت عملية الإرجاع بنجاح"
//             });
//         }

//         /// <summary>
//         /// الحصول على سجل المدفوعات لحجز معين
//         /// </summary>
//         /// <param name="bookingId">معرف الحجز</param>
//         /// <returns>قائمة المدفوعات</returns>
//         [HttpGet("booking/{bookingId}")]
//         [ProducesResponseType(typeof(List<PaymentDto>), 200)]
//         public async Task<IActionResult> GetBookingPayments(string bookingId)
//         {
//             var query = new GetBookingPaymentsQuery { BookingId = bookingId };
//             var result = await _mediator.Send(query);
            
//             return Ok(result);
//         }
//     }

//     /// <summary>
//     /// نموذج استجابة الخطأ
//     /// </summary>
//     public class ErrorResponse
//     {
//         /// <summary>
//         /// رسالة الخطأ الرئيسية
//         /// </summary>
//         public string Message { get; set; }

//         /// <summary>
//         /// تفاصيل إضافية عن الخطأ
//         /// </summary>
//         public List<string> Details { get; set; }
//     }
// }