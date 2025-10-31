// lib/core/enums/section_target_enum.dart

enum SectionTarget {
  properties,
  units,
}

extension SectionTargetBackend on SectionTarget {
  String get backendName {
    switch (this) {
      case SectionTarget.properties:
        return 'Properties';
      case SectionTarget.units:
        return 'Units';
    }
  }

  static SectionTarget? tryParse(String? value) {
    if (value == null) return null;
    final v = value.trim().toLowerCase();
    if (v == 'properties') return SectionTarget.properties;
    if (v == 'units') return SectionTarget.units;
    return null;
  }
}
