import 'dart:convert';

/// Generates a stable unique ID for any piece of content.
/// For text-based items we hash the content so duplicate saves are prevented.
/// For custom items (user-created) we use a timestamp-based ID.
class FavoriteIdHelper {
  FavoriteIdHelper._();

  /// Hash-based ID for known content (prevents duplicates).
  static String forText(String text) {
    final bytes = utf8.encode(text.trim());
    int hash = 0;
    for (final b in bytes) {
      hash = (hash * 31 + b) & 0x7fffffff;
    }
    return 'txt_$hash';
  }

  /// For asma allah — use numeric ID directly.
  static String forAsma(int asmaId) => 'asma_$asmaId';

  /// For podcast items — use title hash.
  static String forPodcast(String title) {
    final bytes = utf8.encode(title.trim());
    int hash = 0;
    for (final b in bytes) {
      hash = (hash * 31 + b) & 0x7fffffff;
    }
    return 'podcast_$hash';
  }

  /// For user-created custom items — timestamp-based unique ID.
  static String forCustom() =>
      'custom_${DateTime.now().millisecondsSinceEpoch}';
}
