using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Sections.Commands.ManageImages
{
    public class ReorderPropertyInSectionImagesCommandHandler : IRequestHandler<ReorderPropertyInSectionImagesCommand, ResultDto<bool>>
    {
        private readonly IPropertyInSectionImageRepository _repo;
        public ReorderPropertyInSectionImagesCommandHandler(IPropertyInSectionImageRepository repo) { _repo = repo; }

        public async Task<ResultDto<bool>> Handle(ReorderPropertyInSectionImagesCommand request, CancellationToken cancellationToken)
        {
            var tuples = request.Assignments.ConvertAll(a => (a.ImageId, a.DisplayOrder));
            var ok = await _repo.UpdateDisplayOrdersAsync(tuples, cancellationToken);
            return ok ? ResultDto<bool>.Ok(true) : ResultDto<bool>.Failed("فشل إعادة الترتيب");
        }
    }
}

