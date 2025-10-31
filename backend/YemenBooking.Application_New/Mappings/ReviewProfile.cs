using AutoMapper;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reviews.DTOs;

namespace YemenBooking.Application.Mappings
{
    /// <summary>
    /// ملف تعريف الخرائط لتحويل بين كيان المراجعة وDTO
    /// Mapping profile for Review and ReviewDto
    /// </summary>
    public class ReviewProfile : Profile
    {
        public ReviewProfile()
        {
            CreateMap<Review, ReviewDto>()
                .ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.Id))
                .ForMember(dest => dest.BookingId, opt => opt.MapFrom(src => src.BookingId))
                .ForMember(dest => dest.Cleanliness, opt => opt.MapFrom(src => src.Cleanliness))
                .ForMember(dest => dest.Service, opt => opt.MapFrom(src => src.Service))
                .ForMember(dest => dest.Location, opt => opt.MapFrom(src => src.Location))
                .ForMember(dest => dest.Value, opt => opt.MapFrom(src => src.Value))
                .ForMember(dest => dest.Comment, opt => opt.MapFrom(src => src.Comment))
                .ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(src => src.CreatedAt))
                .ForMember(dest => dest.Images, opt => opt.MapFrom(src => src.Images));
        }
    }
} 