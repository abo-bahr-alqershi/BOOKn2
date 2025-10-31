using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.Sections.Commands.DeleteUnit
{
    public class DeleteUnitInSectionImageCommandHandler : IRequestHandler<DeleteUnitInSectionImageCommand, ResultDto<bool>>
    {
        private readonly IUnitInSectionImageRepository _repo;
        private readonly IFileStorageService _files;
        private readonly IAuditService _auditService;
        private readonly ICurrentUserService _currentUserService;
        public DeleteUnitInSectionImageCommandHandler(IUnitInSectionImageRepository repo, IFileStorageService files, IAuditService auditService, ICurrentUserService currentUserService)
        {
            _repo = repo;
            _files = files;
            _auditService = auditService;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<bool>> Handle(DeleteUnitInSectionImageCommand request, CancellationToken cancellationToken)
        {
            var entity = await _repo.GetByIdAsync(request.ImageId, cancellationToken);
            if (entity == null) return ResultDto<bool>.Failed("الصورة غير موجودة");
            var url = entity.Url;
            var ok = await _repo.DeleteAsync(request.ImageId, cancellationToken);
            if (ok && request.Permanent && !string.IsNullOrWhiteSpace(url))
            {
                await _files.DeleteFileAsync(url!, cancellationToken);
            }
            if (ok)
            {
                await _auditService.LogAuditAsync(
                    entityType: nameof(UnitInSectionImage),
                    entityId: entity.UnitInSectionId ?? System.Guid.Empty,
                    action: AuditAction.DELETE,
                    oldValues: System.Text.Json.JsonSerializer.Serialize(new { entity.Id, entity.Name, entity.Url }),
                    newValues: null,
                    performedBy: _currentUserService.UserId,
                    notes: $"تم حذف صورة عنصر وحدة في القسم بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                    cancellationToken: cancellationToken);
            }
            return ResultDto<bool>.Ok(ok);
        }
    }
}

