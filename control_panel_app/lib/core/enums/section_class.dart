// lib/core/enums/section_class.dart

enum SectionClass {
  classA,
  classB,
  classC,
  classD,
}

extension SectionClassApi on SectionClass {
  String get apiValue {
    switch (this) {
      case SectionClass.classA:
        return 'ClassA';
      case SectionClass.classB:
        return 'ClassB';
      case SectionClass.classC:
        return 'ClassC';
      case SectionClass.classD:
        return 'ClassD';
    }
  }

  static SectionClass? tryParse(String? value) {
    if (value == null) return null;
    switch (value.trim()) {
      case 'ClassA':
        return SectionClass.classA;
      case 'ClassB':
        return SectionClass.classB;
      case 'ClassC':
        return SectionClass.classC;
      case 'ClassD':
        return SectionClass.classD;
      default:
        return null;
    }
  }
}
