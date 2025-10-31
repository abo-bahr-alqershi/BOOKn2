using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace YemenBooking.Api.Controllers.Common
{
    /// <summary>
    /// مقدم أساسي للتحكم بنقاط النهاية العامة
    /// Base controller for common endpoints
    /// </summary>
    [ApiController]
    [Route("api/common/[controller]")]
    public abstract class BaseCommonController : ControllerBase
    {
        protected readonly IMediator _mediator;

        public BaseCommonController(IMediator mediator)
        {
            _mediator = mediator;
        }
    }
} 