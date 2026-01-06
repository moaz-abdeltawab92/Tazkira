class AzkarParser {
  static final RegExp _countRegex = RegExp(
    r'\((.+?)\s*(مرات|مرة)\)',
    multiLine: true,
  );

  static ({int count, String cleanText}) parse(String rawText) {
    int count = 1;
    String cleanText = rawText;

    final match = _countRegex.firstMatch(rawText);
    if (match != null) {
      final countString = match.group(1)?.trim() ?? '';
      count = _parseArabicCount(countString);

      cleanText = rawText.replaceFirst(match.group(0)!, '').trim();
    }

    return (count: count, cleanText: cleanText);
  }

  static int _parseArabicCount(String text) {
    if (text.contains('ثلاث') || text == '3') return 3;
    if (text.contains('أربع') || text == '4') return 4;
    if (text.contains('سبع') || text == '7') return 7;
    if (text.contains('عشر') || text == '10') return 10;
    if (text.contains('مائة') || text == '100') return 100;
    if (text.contains('33')) return 33;
    if (text.contains('34')) return 34;

    final digit = int.tryParse(text);
    return digit ?? 1;
  }
}
