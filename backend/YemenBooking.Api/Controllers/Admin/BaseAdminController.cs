using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace YemenBooking.Api.Controllers.Admin
{
    [ApiController]
    [Route("api/admin/[controller]")]
    [Authorize(Roles = "Admin,Owner")]
    public abstract class BaseAdminController : ControllerBase
    {
        protected readonly IMediator _mediator;

        public BaseAdminController(IMediator mediator)
        {
            _mediator = mediator;
        }
    }
}