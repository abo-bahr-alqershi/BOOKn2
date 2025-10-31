using AutoMapper;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Reviews.DTOs;

namespace YemenBooking.Application.Mappings;

/// <summary>
/// ملف تعريف الخرائط لتحويل بين كيان صورة التقييم وDTO
/// Mapping profile for ReviewImage and ReviewImageDto
/// </summary>
public class ReviewImageProfile : Profile
{
    public ReviewImageProfile()
    {
        CreateMap<ReviewImage, ReviewImageDto>()
            .ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.Id))
            .ForMember(dest => dest.ReviewId, opt => opt.MapFrom(src => src.ReviewId))
            .ForMember(dest => dest.Name, opt => opt.MapFrom(src => src.Name))
            .ForMember(dest => dest.Url, opt => opt.MapFrom(src => src.Url))
            .ForMember(dest => dest.SizeBytes, opt => opt.MapFrom(src => src.SizeBytes))
            .ForMember(dest => dest.Type, opt => opt.MapFrom(src => src.Type))
            .ForMember(dest => dest.Category, opt => opt.MapFrom(src => src.Category))
            .ForMember(dest => dest.Caption, opt => opt.MapFrom(src => src.Caption))
            .ForMember(dest => dest.AltText, opt => opt.MapFrom(src => src.AltText))
            .ForMember(dest => dest.UploadedAt, opt => opt.MapFrom(src => src.UploadedAt));

        CreateMap<ReviewImageDto, ReviewImage>()
            .ForMember(dest => dest.Id, opt => opt.Ignore())
            .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
            .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore())
            .ForMember(dest => dest.IsDeleted, opt => opt.Ignore())
            .ForMember(dest => dest.DeletedAt, opt => opt.Ignore())
            .ForMember(dest => dest.Name, opt => opt.MapFrom(src => src.Name))
            .ForMember(dest => dest.Url, opt => opt.MapFrom(src => src.Url))
            .ForMember(dest => dest.SizeBytes, opt => opt.MapFrom(src => src.SizeBytes))
            .ForMember(dest => dest.Type, opt => opt.MapFrom(src => src.Type))
            .ForMember(dest => dest.Category, opt => opt.MapFrom(src => src.Category))
            .ForMember(dest => dest.Caption, opt => opt.MapFrom(src => src.Caption))
            .ForMember(dest => dest.AltText, opt => opt.MapFrom(src => src.AltText))
            .ForMember(dest => dest.UploadedAt, opt => opt.MapFrom(src => src.UploadedAt));
    }
} 