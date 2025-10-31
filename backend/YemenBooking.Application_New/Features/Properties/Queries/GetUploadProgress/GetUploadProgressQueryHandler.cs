using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Properties.Queries.GetUploadProgress
{
    /// <summary>
    /// معالج استعلام تتبع تقدم رفع الصورة بواسطة معرف المهمة
    /// Handler for GetUploadProgressQuery to track image upload progress by task ID
    /// </summary>
    public class GetUploadProgressQueryHandler : IRequestHandler<GetUploadProgressQuery, ResultDto<UploadProgressDto>>
    {
        private readonly IFileStorageService _fileStorageService;
        private readonly ICurrentUserService _currentUserService;

        public GetUploadProgressQueryHandler(IFileStorageService fileStorageService, ICurrentUserService currentUserService)
        {
            _fileStorageService = fileStorageService;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<UploadProgressDto>> Handle(GetUploadProgressQuery request, CancellationToken cancellationToken)
        {
            // TODO: تنفيذ منطق تتبع تقدم الرفع باستخدام request.TaskId
            throw new NotImplementedException("منطق تتبع تقدم الرفع لم يتم تنفيذه بعد");
        }
    }
} 