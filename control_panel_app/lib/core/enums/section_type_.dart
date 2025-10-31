// // lib/core/enums/section_type.dart

// /// SectionType aligned with backend YemenBooking.Core.Enums.SectionType
// /// Values: Featured, Popular, NewArrivals, TopRated, Discounted, NearBy, Recommended, Category, Custom
// enum SectionTypeEnum {
//   featured,
//   popular,
//   newArrivals,
//   topRated,
//   discounted,
//   nearBy,
//   recommended,
//   category,
//   custom,
// }

// extension SectionTypeEnumApi on SectionTypeEnum {
//   /// Backend enum string expected by API
//   String get apiValue {
//     switch (this) {
//       case SectionTypeEnum.featured:
//         return 'Featured';
//       case SectionTypeEnum.popular:
//         return 'Popular';
//       case SectionTypeEnum.newArrivals:
//         return 'NewArrivals';
//       case SectionTypeEnum.topRated:
//         return 'TopRated';
//       case SectionTypeEnum.discounted:
//         return 'Discounted';
//       case SectionTypeEnum.nearBy:
//         return 'NearBy';
//       case SectionTypeEnum.recommended:
//         return 'Recommended';
//       case SectionTypeEnum.category:
//         return 'Category';
//       case SectionTypeEnum.custom:
//         return 'Custom';
//     }
//   }

//   static SectionTypeEnum? tryParse(String? value) {
//     if (value == null) return null;
//     final v = value.trim();
//     switch (v) {
//       case 'Featured':
//         return SectionTypeEnum.featured;
//       case 'Popular':
//         return SectionTypeEnum.popular;
//       case 'NewArrivals':
//         return SectionTypeEnum.newArrivals;
//       case 'TopRated':
//         return SectionTypeEnum.topRated;
//       case 'Discounted':
//         return SectionTypeEnum.discounted;
//       case 'NearBy':
//         return SectionTypeEnum.nearBy;
//       case 'Recommended':
//         return SectionTypeEnum.recommended;
//       case 'Category':
//         return SectionTypeEnum.category;
//       case 'Custom':
//         return SectionTypeEnum.custom;
//       default:
//         return null;
//     }
//   }
// }
