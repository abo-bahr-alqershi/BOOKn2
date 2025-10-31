using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Properties.Commands.ManageImages
{
    /// <summary>
    /// معالج أمر حذف صور متعددة (مؤقت أو دائم)
    /// Handler for DeleteImagesCommand to bulk delete images (soft or permanent)
    /// </summary>
    public class DeleteImagesCommandHandler : IRequestHandler<DeleteImagesCommand, ResultDto<bool>>
    {
        private readonly IPropertyImageRepository _imageRepository;
        private readonly IFileStorageService _fileStorageService;
        private readonly IUnitOfWork _unitOfWork;

        public DeleteImagesCommandHandler(
            IPropertyImageRepository imageRepository,
            IFileStorageService fileStorageService,
            IUnitOfWork unitOfWork)
        {
            _imageRepository = imageRepository;
            _fileStorageService = fileStorageService;
            _unitOfWork = unitOfWork;
        }

        public async Task<ResultDto<bool>> Handle(DeleteImagesCommand request, CancellationToken cancellationToken)
        {
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                foreach (var imageId in request.ImageIds)
                {
                    var image = await _imageRepository.GetPropertyImageByIdAsync(imageId, cancellationToken);
                    if (image == null) continue;

                    var deleted = await _imageRepository.DeletePropertyImageAsync(imageId, cancellationToken);
                    if (deleted && request.Permanent && !string.IsNullOrEmpty(image.Url))
                    {
                        await _fileStorageService.DeleteFileAsync(image.Url, cancellationToken);
                    }
                }
            }, cancellationToken);

            return ResultDto<bool>.Ok(true, "تم حذف الصور المطلوبة بنجاح");
        }
    }

    /// <summary>
    /// معالج أمر حذف الصور وفق مفتاح مؤقت
    /// </summary>
    public class DeleteImagesByTempKeyCommandHandler : IRequestHandler<DeleteImagesByTempKeyCommand, ResultDto<bool>>
    {
        private readonly IPropertyImageRepository _imageRepository;
        private readonly IFileStorageService _fileStorageService;
        private readonly IUnitOfWork _unitOfWork;

        public DeleteImagesByTempKeyCommandHandler(
            IPropertyImageRepository imageRepository,
            IFileStorageService fileStorageService,
            IUnitOfWork unitOfWork)
        {
            _imageRepository = imageRepository;
            _fileStorageService = fileStorageService;
            _unitOfWork = unitOfWork;
        }

        public async Task<ResultDto<bool>> Handle(DeleteImagesByTempKeyCommand request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.TempKey))
                return ResultDto<bool>.Failed("TempKey is required");

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                var query = _imageRepository.GetQueryable().Where(i => i.TempKey == request.TempKey);
                var toDelete = await query.ToListAsync(cancellationToken);
                foreach (var image in toDelete)
                {
                    var deleted = await _imageRepository.DeletePropertyImageAsync(image.Id, cancellationToken);
                    if (deleted && request.Permanent && !string.IsNullOrEmpty(image.Url))
                    {
                        await _fileStorageService.DeleteFileAsync(image.Url, cancellationToken);
                    }
                }
            }, cancellationToken);

            return ResultDto<bool>.Ok(true, "تم حذف صور المفتاح المؤقت بنجاح");
        }
    }
} 