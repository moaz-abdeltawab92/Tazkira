import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazkira_app/features/my_favorites/data/models/favorite_item.dart';
import 'package:tazkira_app/features/my_favorites/data/models/favorite_item_type.dart';
import 'package:tazkira_app/features/my_favorites/data/services/favorite_id_helper.dart';

class FavoritesService {
  static const _prefKey = 'user_favorites_json_v2';
  static const _migratedKey = 'legacy_favorites_migrated_v1';

  static List<FavoriteItem>? _cachedItems;

  static Future<List<FavoriteItem>> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Auto-migrate legacy favorites on first load
    final isMigrated = prefs.getBool(_migratedKey) ?? false;
    if (!isMigrated) {
      await _migrateLegacy(prefs);
    }

    final rawList = prefs.getStringList(_prefKey) ?? [];
    final items = <FavoriteItem>[];
    for (final jsonStr in rawList) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        items.add(FavoriteItem.fromMap(map));
      } catch (_) {}
    }
    // Sort descending by savedAt
    items.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    _cachedItems = items;
    return items;
  }

  static Future<void> _saveToPrefs(List<FavoriteItem> items) async {
    _cachedItems = items;
    final prefs = await SharedPreferences.getInstance();
    final rawList = items.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList(_prefKey, rawList);
  }

  /// Automatically migrates old favorite keys (favorite_ad3ya, favorite_hadiths, favorite_asma_allah)
  static Future<void> _migrateLegacy(SharedPreferences prefs) async {
    final existingRaw = prefs.getStringList(_prefKey) ?? [];
    final itemsMap = <String, FavoriteItem>{};

    for (final jsonStr in existingRaw) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final item = FavoriteItem.fromMap(map);
        itemsMap[item.id] = item;
      } catch (_) {}
    }

    // 1. Migrate Doaa
    final oldDoaa = prefs.getStringList('favorite_ad3ya') ?? [];
    for (final text in oldDoaa) {
      final id = FavoriteIdHelper.forText(text);
      if (!itemsMap.containsKey(id)) {
        itemsMap[id] = FavoriteItem(
          id: id,
          type: FavoriteItemType.doaa,
          title: 'دعاء',
          content: text,
          savedAt: DateTime.now(),
        );
      }
    }

    // 2. Migrate Hadiths
    final oldHadiths = prefs.getStringList('favorite_hadiths') ?? [];
    for (final text in oldHadiths) {
      final id = FavoriteIdHelper.forText(text);
      if (!itemsMap.containsKey(id)) {
        itemsMap[id] = FavoriteItem(
          id: id,
          type: FavoriteItemType.hadith,
          title: 'حديث نبوي',
          content: text,
          savedAt: DateTime.now(),
        );
      }
    }

    // Save back merged list
    final updatedList = itemsMap.values.toList();
    updatedList.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    final rawList = updatedList.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList(_prefKey, rawList);
    await prefs.setBool(_migratedKey, true);
  }

  // ─── Add ───────────────────────────────────────────────────────────────────
  static Future<void> addItem(FavoriteItem item) async {
    final items = await getAllItems();
    items.removeWhere((i) => i.id == item.id);
    items.insert(0, item);
    await _saveToPrefs(items);
  }

  // ─── Remove ────────────────────────────────────────────────────────────────
  static Future<void> removeItem(String id) async {
    final items = await getAllItems();
    items.removeWhere((i) => i.id == id);
    await _saveToPrefs(items);
  }

  // ─── Toggle ────────────────────────────────────────────────────────────────
  /// Returns true if item was added, false if it was removed.
  static Future<bool> toggleItem(FavoriteItem item) async {
    final exists = await isItemSaved(item.id);
    if (exists) {
      await removeItem(item.id);
      return false;
    } else {
      await addItem(item);
      return true;
    }
  }

  // ─── Check ─────────────────────────────────────────────────────────────────
  static bool? isSavedSync(String id) {
    if (_cachedItems == null) return null;
    return _cachedItems!.any((i) => i.id == id);
  }

  static Future<bool> isItemSaved(String id) async {
    final items = await getAllItems();
    return items.any((i) => i.id == id);
  }

  // ─── Get All ───────────────────────────────────────────────────────────────
  static Future<List<FavoriteItem>> getAllItems() async {
    if (_cachedItems != null) {
      return List.from(_cachedItems!);
    }
    return await _loadFromPrefs();
  }

  // ─── Get by Type ──────────────────────────────────────────────────────────
  static Future<List<FavoriteItem>> getItemsByType(FavoriteItemType type) async {
    final items = await getAllItems();
    return items.where((i) => i.type == type).toList();
  }

  // ─── Count ────────────────────────────────────────────────────────────────
  static Future<int> getCount() async {
    final items = await getAllItems();
    return items.length;
  }
}
