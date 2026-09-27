class ArabicSearchUtils {
  /// Removes diacritics (Tashkeel) and normalizes Arabic characters
  /// for flexible search matching.
  static String normalize(String input) {
    if (input.isEmpty) return input;

    // 1. Remove diacritics (Fatha, Damma, Kasra, Sukun, Shadda, Tanween, etc.)
    final diacriticsRegex =
        RegExp(r'[\u064B-\u0652\u0640\u0653-\u0655\u0670\u0656-\u065F]');
    String text = input.replaceAll(diacriticsRegex, '');

    // 2. Normalize letter variations (Hamzas, Alef, Ta Marbouta, Alef Maqsura, etc.)
    text = text.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll('ى', 'ي');
    text = text.replaceAll('ؤ', 'و');
    text = text.replaceAll('ئ', 'ي');

    return text.toLowerCase().trim();
  }

  /// Returns true if [source] contains [query] after normalizing both.
  static bool matches(String source, String query) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return true;
    final normalizedSource = normalize(source);
    return normalizedSource.contains(normalizedQuery);
  }
}
