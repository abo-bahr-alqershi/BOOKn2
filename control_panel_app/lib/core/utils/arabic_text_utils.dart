class ArabicTextUtils {
  ArabicTextUtils._();

  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF]');
  static const _transparentChars = {
    0x064B,
    0x064C,
    0x064D,
    0x064E,
    0x064F,
    0x0650,
    0x0651,
    0x0652,
    0x0653,
    0x0654,
    0x0655,
    0x0656,
    0x0657,
    0x0658,
    0x0659,
    0x065A,
    0x065B,
    0x065C,
    0x065D,
    0x065E,
    0x065F,
    0x0670,
  };

  static const Map<int, _ArabicCharData> _chars = {
    0x0621: _ArabicCharData(isolated: 0xFE80),
    0x0622:
        _ArabicCharData(isolated: 0xFE81, finalForm: 0xFE82, connectPrev: true),
    0x0623:
        _ArabicCharData(isolated: 0xFE83, finalForm: 0xFE84, connectPrev: true),
    0x0624:
        _ArabicCharData(isolated: 0xFE85, finalForm: 0xFE86, connectPrev: true),
    0x0625:
        _ArabicCharData(isolated: 0xFE87, finalForm: 0xFE88, connectPrev: true),
    0x0626: _ArabicCharData(
      isolated: 0xFE89,
      finalForm: 0xFE8A,
      initial: 0xFE8B,
      medial: 0xFE8C,
      connectPrev: true,
      connectNext: true,
    ),
    0x0627:
        _ArabicCharData(isolated: 0xFE8D, finalForm: 0xFE8E, connectPrev: true),
    0x0628: _ArabicCharData(
      isolated: 0xFE8F,
      finalForm: 0xFE90,
      initial: 0xFE91,
      medial: 0xFE92,
      connectPrev: true,
      connectNext: true,
    ),
    0x0629:
        _ArabicCharData(isolated: 0xFE93, finalForm: 0xFE94, connectPrev: true),
    0x062A: _ArabicCharData(
      isolated: 0xFE95,
      finalForm: 0xFE96,
      initial: 0xFE97,
      medial: 0xFE98,
      connectPrev: true,
      connectNext: true,
    ),
    0x062B: _ArabicCharData(
      isolated: 0xFE99,
      finalForm: 0xFE9A,
      initial: 0xFE9B,
      medial: 0xFE9C,
      connectPrev: true,
      connectNext: true,
    ),
    0x062C: _ArabicCharData(
      isolated: 0xFE9D,
      finalForm: 0xFE9E,
      initial: 0xFE9F,
      medial: 0xFEA0,
      connectPrev: true,
      connectNext: true,
    ),
    0x062D: _ArabicCharData(
      isolated: 0xFEA1,
      finalForm: 0xFEA2,
      initial: 0xFEA3,
      medial: 0xFEA4,
      connectPrev: true,
      connectNext: true,
    ),
    0x062E: _ArabicCharData(
      isolated: 0xFEA5,
      finalForm: 0xFEA6,
      initial: 0xFEA7,
      medial: 0xFEA8,
      connectPrev: true,
      connectNext: true,
    ),
    0x062F:
        _ArabicCharData(isolated: 0xFEA9, finalForm: 0xFEAA, connectPrev: true),
    0x0630:
        _ArabicCharData(isolated: 0xFEAB, finalForm: 0xFEAC, connectPrev: true),
    0x0631:
        _ArabicCharData(isolated: 0xFEAD, finalForm: 0xFEAE, connectPrev: true),
    0x0632:
        _ArabicCharData(isolated: 0xFEAF, finalForm: 0xFEB0, connectPrev: true),
    0x0633: _ArabicCharData(
      isolated: 0xFEB1,
      finalForm: 0xFEB2,
      initial: 0xFEB3,
      medial: 0xFEB4,
      connectPrev: true,
      connectNext: true,
    ),
    0x0634: _ArabicCharData(
      isolated: 0xFEB5,
      finalForm: 0xFEB6,
      initial: 0xFEB7,
      medial: 0xFEB8,
      connectPrev: true,
      connectNext: true,
    ),
    0x0635: _ArabicCharData(
      isolated: 0xFEB9,
      finalForm: 0xFEBA,
      initial: 0xFEBB,
      medial: 0xFEBC,
      connectPrev: true,
      connectNext: true,
    ),
    0x0636: _ArabicCharData(
      isolated: 0xFEBD,
      finalForm: 0xFEBE,
      initial: 0xFEBF,
      medial: 0xFEC0,
      connectPrev: true,
      connectNext: true,
    ),
    0x0637: _ArabicCharData(
      isolated: 0xFEC1,
      finalForm: 0xFEC2,
      initial: 0xFEC3,
      medial: 0xFEC4,
      connectPrev: true,
      connectNext: true,
    ),
    0x0638: _ArabicCharData(
      isolated: 0xFEC5,
      finalForm: 0xFEC6,
      initial: 0xFEC7,
      medial: 0xFEC8,
      connectPrev: true,
      connectNext: true,
    ),
    0x0639: _ArabicCharData(
      isolated: 0xFEC9,
      finalForm: 0xFECA,
      initial: 0xFECB,
      medial: 0xFECC,
      connectPrev: true,
      connectNext: true,
    ),
    0x063A: _ArabicCharData(
      isolated: 0xFECD,
      finalForm: 0xFECE,
      initial: 0xFECF,
      medial: 0xFED0,
      connectPrev: true,
      connectNext: true,
    ),
    0x0641: _ArabicCharData(
      isolated: 0xFED1,
      finalForm: 0xFED2,
      initial: 0xFED3,
      medial: 0xFED4,
      connectPrev: true,
      connectNext: true,
    ),
    0x0642: _ArabicCharData(
      isolated: 0xFED5,
      finalForm: 0xFED6,
      initial: 0xFED7,
      medial: 0xFED8,
      connectPrev: true,
      connectNext: true,
    ),
    0x0643: _ArabicCharData(
      isolated: 0xFED9,
      finalForm: 0xFEDA,
      initial: 0xFEDB,
      medial: 0xFEDC,
      connectPrev: true,
      connectNext: true,
    ),
    0x0644: _ArabicCharData(
      isolated: 0xFEDD,
      finalForm: 0xFEDE,
      initial: 0xFEDF,
      medial: 0xFEE0,
      connectPrev: true,
      connectNext: true,
    ),
    0x0645: _ArabicCharData(
      isolated: 0xFEE1,
      finalForm: 0xFEE2,
      initial: 0xFEE3,
      medial: 0xFEE4,
      connectPrev: true,
      connectNext: true,
    ),
    0x0646: _ArabicCharData(
      isolated: 0xFEE5,
      finalForm: 0xFEE6,
      initial: 0xFEE7,
      medial: 0xFEE8,
      connectPrev: true,
      connectNext: true,
    ),
    0x0647: _ArabicCharData(
      isolated: 0xFEE9,
      finalForm: 0xFEEA,
      initial: 0xFEEB,
      medial: 0xFEEC,
      connectPrev: true,
      connectNext: true,
    ),
    0x0648:
        _ArabicCharData(isolated: 0xFEED, finalForm: 0xFEEE, connectPrev: true),
    0x0649:
        _ArabicCharData(isolated: 0xFEEF, finalForm: 0xFEF0, connectPrev: true),
    0x064A: _ArabicCharData(
      isolated: 0xFEF1,
      finalForm: 0xFEF2,
      initial: 0xFEF3,
      medial: 0xFEF4,
      connectPrev: true,
      connectNext: true,
    ),
  };

  static const Map<int, _LamAlefForm> _lamAlefForms = {
    0x0622: _LamAlefForm(isolated: 0xFEF5, finalForm: 0xFEF6),
    0x0623: _LamAlefForm(isolated: 0xFEF7, finalForm: 0xFEF8),
    0x0625: _LamAlefForm(isolated: 0xFEF9, finalForm: 0xFEFA),
    0x0627: _LamAlefForm(isolated: 0xFEFB, finalForm: 0xFEFC),
  };

  static bool containsArabic(String text) => _arabicRegex.hasMatch(text);

  static String shape(String text) {
    if (text.isEmpty || !containsArabic(text)) {
      return text;
    }

    final runes = text.runes.toList(growable: false);
    final buffer = StringBuffer();

    int index = 0;
    while (index < runes.length) {
      final code = runes[index];

      if (_transparentChars.contains(code)) {
        buffer.writeCharCode(code);
        index++;
        continue;
      }

      final data = _chars[code];
      if (data == null) {
        buffer.writeCharCode(code);
        index++;
        continue;
      }

      final prevIndex = _findPrevLetter(runes, index - 1);
      final nextIndex = _findNextLetter(runes, index + 1);

      final prevCode = prevIndex != null ? runes[prevIndex] : null;
      final prevData = prevCode != null ? _chars[prevCode] : null;

      final nextCode = nextIndex != null ? runes[nextIndex] : null;
      final nextData = nextCode != null ? _chars[nextCode] : null;

      if (code == 0x0644 && nextCode != null) {
        final lamAlef = _lamAlefForms[nextCode];
        if (lamAlef != null) {
          final connectsPrev =
              prevData != null && prevData.connectNext && data.connectPrev;
          buffer.writeCharCode(
            connectsPrev ? lamAlef.finalForm : lamAlef.isolated,
          );
          index = nextIndex! + 1;
          continue;
        }
      }

      final connectsPrev =
          prevData != null && prevData.connectNext && data.connectPrev;
      final connectsNext =
          nextData != null && data.connectNext && nextData.connectPrev;

      buffer.writeCharCode(
        _resolveForm(data,
            connectsPrev: connectsPrev, connectsNext: connectsNext),
      );
      index++;
    }

    return buffer.toString();
  }

  static int? _findPrevLetter(List<int> runes, int start) {
    for (var i = start; i >= 0; i--) {
      final code = runes[i];
      if (_transparentChars.contains(code)) {
        continue;
      }
      if (_chars.containsKey(code)) {
        return i;
      }
      break;
    }
    return null;
  }

  static int? _findNextLetter(List<int> runes, int start) {
    for (var i = start; i < runes.length; i++) {
      final code = runes[i];
      if (_transparentChars.contains(code)) {
        continue;
      }
      if (_chars.containsKey(code)) {
        return i;
      }
      break;
    }
    return null;
  }

  static int _resolveForm(
    _ArabicCharData data, {
    required bool connectsPrev,
    required bool connectsNext,
  }) {
    if (connectsPrev && connectsNext && data.medial != null) {
      return data.medial!;
    }
    if (connectsPrev && data.finalForm != null) {
      return data.finalForm!;
    }
    if (connectsNext && data.initial != null) {
      return data.initial!;
    }
    return data.isolated;
  }
}

class _ArabicCharData {
  final int isolated;
  final int? finalForm;
  final int? initial;
  final int? medial;
  final bool connectPrev;
  final bool connectNext;

  const _ArabicCharData({
    required this.isolated,
    this.finalForm,
    this.initial,
    this.medial,
    this.connectPrev = false,
    this.connectNext = false,
  });
}

class _LamAlefForm {
  final int isolated;
  final int finalForm;

  const _LamAlefForm({
    required this.isolated,
    required this.finalForm,
  });
}
