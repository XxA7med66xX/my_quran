class ArabicTextProcessor {
  static const Map<String, String> _spellVariants = {
    'الرحمن': 'الرحمان',
    'هذا': 'هاذا',
    'ذلك': 'ذالك',
    'ذلكم': 'ذالكم',
    'لكن': 'لاكن',
    'إله': 'إلاه',
    'اله': 'الاه',
    'الهكم': 'الاهكم',
    'السلام': 'السلام',
    'اسرائيل': 'اسراءيل',
    'اسحق': 'اسحاق',
    'ابرهيم': 'ابراهيم',
    'اسمعيل': 'اسماعيل',
    'موسىا': 'موسى',
    'صرط': 'صراط',
  };

  static String _stripPuaAndBidi(String s) {
    // PUA glyphs: U+E000–U+F8FF
    final stripped = s.replaceAll(RegExp(r'[\uE000-\uF8FF]'), '');
    // Bidi markers
    return stripped.replaceAll(
      RegExp(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]'),
      '',
    );
  }

  static String removeDiacritics(String text) {
    // Convert Quran "small letters" into real letters BEFORE stripping marks.
    final updated = text
        .replaceAll('\u0670', 'ا') // dagger alif
        .replaceAll('\u06E5', 'و') // small waw ۥ
        .replaceAll('\u06E6', 'ي') // small high yeh ۦ
        .replaceAll('\u06E7', 'ي') // small high yeh variant ۧ
        .replaceAll('\u06E8', 'ن'); // small high noon ۨ

    // Now strip remaining diacritics / Quran marks
    return updated.replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06ED\u08D3-\u08FF]'),
      '',
    );
  }

  static String normalize(String text) {
    String normalized = _spellVariants[text] ?? text;
    normalized = _stripPuaAndBidi(normalized);

    normalized = normalized.replaceAll(
      RegExp(r'[\p{P}\p{S}\p{N}\-\(\)\[\]\{\}]+', unicode: true),
      '',
    );

    normalized = removeDiacritics(normalized);

    // Alef variants
    normalized = normalized.replaceAll(RegExp('[أإآٱ]'), 'ا');

    // Taa marbuta -> haa (end of word only)
    normalized = normalized.replaceAll(RegExp(r'ة$'), 'ه');

    // Alef maksura
    normalized = normalized.replaceAll('ى', 'ي');

    // Hamza forms (less false positives than ؤ->و)
    normalized = normalized.replaceAll('ؤ', 'ء');
    normalized = normalized.replaceAll('ئ', 'ء');
    normalized = normalized.replaceAll('ء', '');

    // Tatweel
    normalized = normalized.replaceAll('ـ', '');

    return normalized.trim();
  }

  static List<String> tokenize(String text) {
    if (text.isEmpty) return [];
    return text
        .replaceAll(
          RegExp(r'[\p{P}\p{S}\p{N}\-\(\)\[\]\{\}]+', unicode: true),
          ' ',
        )
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }
}
