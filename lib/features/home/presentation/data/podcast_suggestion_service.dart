import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PodcastSuggestionService {
  /// Sends a podcast/channel suggestion to Telegram Bot
  static Future<bool> sendSuggestion({
    required String title,
    required String url,
    String? note,
  }) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Read credentials dynamically from Remote Config only
      final botToken = remoteConfig.getString('telegram_bot_token').trim();
      final chatId = remoteConfig.getString('telegram_chat_id').trim();

      if (botToken.isEmpty || chatId.isEmpty) {
        debugPrint('Telegram credentials not configured in Remote Config.');
        return false;
      }

      final now = DateTime.now();
      final dateFormatted =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final cleanTitle = htmlEscape.convert(title.trim());
      final cleanUrl = htmlEscape.convert(url.trim());
      final cleanNote = note != null && note.trim().isNotEmpty
          ? htmlEscape.convert(note.trim())
          : null;

      final messageText = '''
<b>🎙️ اقتراح بودكاست / قناة دينية جديدة</b>
----------------------------------------
📌 <b>الاسم:</b> $cleanTitle
🔗 <b>الرابط:</b> $cleanUrl
${cleanNote != null ? '💬 <b>ملاحظات:</b> $cleanNote\n' : ''}⏰ <b>التاريخ:</b> $dateFormatted
''';

      final uri = Uri.parse(
          'https://api.telegram.org/bot$botToken/sendMessage');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': messageText,
          'parse_mode': 'HTML',
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
            'Telegram API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to send podcast suggestion: $e');
      return false;
    }
  }
}

