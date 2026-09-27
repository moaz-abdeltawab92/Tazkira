import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:tazkira_app/features/home/presentation/data/podcast_item.dart';
import 'package:tazkira_app/features/home/presentation/data/pocast_data.dart';

class PodcastService {
  static const String remoteConfigKey = 'podcasts_json';

  /// Get the current list of podcasts.
  /// Tries Firebase Remote Config first. If invalid, empty, or offline without fetch,
  /// falls back to local `podcasts` list.
  static List<PodcastItem> getPodcasts() {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      final rawJson = remoteConfig.getString(remoteConfigKey);

      if (rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        final remoteItems = decoded
            .map((item) => PodcastItem.fromJson(item as Map<String, dynamic>))
            .where((item) => item.title.isNotEmpty && item.url.isNotEmpty)
            .toList();

        if (remoteItems.isNotEmpty) {
          return remoteItems;
        }
      }
    } catch (e) {
      debugPrint('Error loading podcasts from Firebase Remote Config: $e');
    }

    // Fallback to local hardcoded list if Remote Config is unavailable or empty
    return podcasts;
  }

  /// Converts the local podcast list to a JSON string formatted for Firebase Remote Config
  static String exportLocalPodcastsToJson() {
    final list = podcasts.map((item) => item.toJson()).toList();
    return jsonEncode(list);
  }
}
