// lib/core/enums/section_display_style.dart

/// DisplayStyle aligned with backend YemenBooking.Core.Enums.DisplayStyle
/// Values: Grid, List, Carousel, Map
enum SectionDisplayStyle {
  grid,
  list,
  carousel,
  map,
}

extension SectionDisplayStyleApi on SectionDisplayStyle {
  String get apiValue {
    switch (this) {
      case SectionDisplayStyle.grid:
        return 'Grid';
      case SectionDisplayStyle.list:
        return 'List';
      case SectionDisplayStyle.carousel:
        return 'Carousel';
      case SectionDisplayStyle.map:
        return 'Map';
    }
  }

  static SectionDisplayStyle? tryParse(String? value) {
    if (value == null) return null;
    final v = value.trim();
    switch (v) {
      case 'Grid':
        return SectionDisplayStyle.grid;
      case 'List':
        return SectionDisplayStyle.list;
      case 'Carousel':
        return SectionDisplayStyle.carousel;
      case 'Map':
        return SectionDisplayStyle.map;
      default:
        return null;
    }
  }
}

