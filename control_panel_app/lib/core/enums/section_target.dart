// lib/core/enums/section_target.dart

/// SectionTarget aligned with backend YemenBooking.Core.Enums.SectionTarget
/// Values: Properties, Units
enum SectionTarget {
  properties,
  units,
}

extension SectionTargetApi on SectionTarget {
  String get apiValue {
    switch (this) {
      case SectionTarget.properties:
        return 'Properties';
      case SectionTarget.units:
        return 'Units';
    }
  }

  static SectionTarget? tryParse(String? value) {
    if (value == null) return null;
    final v = value.trim();
    switch (v) {
      case 'Properties':
        return SectionTarget.properties;
      case 'Units':
        return SectionTarget.units;
      default:
        return null;
    }
  }
}

