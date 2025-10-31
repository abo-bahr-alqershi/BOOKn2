using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Services
{
    // الإبقاء على فئة الخدمة للتوافق، لكن بدون أي منطق لأن توليد المصغرات أصبح على العميل
    public class MediaThumbnailService : IMediaThumbnailService
    {
        public MediaThumbnailService(ILogger<MediaThumbnailService> logger) { }
    }
}

