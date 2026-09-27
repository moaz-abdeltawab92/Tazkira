import 'package:tazkira_app/features/my_favorites/data/models/favorite_item_type.dart';

class FavoriteItem {
  final String id; // unique identifier (hash of content or UUID for custom)
  final FavoriteItemType type;
  final String title; // العنوان المختصر (اسم السورة، عنوان السنة، ...)
  final String content; // النص الكامل
  final String? subtitle; // تصنيف فرعي (مثلاً: "أذكار الصباح")
  final String? extraData; // بيانات إضافية JSON (مثلاً: الراوي، الدليل، URL)
  final DateTime savedAt;

  const FavoriteItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.subtitle,
    this.extraData,
    required this.savedAt,
  });

  bool get isCustom => type == FavoriteItemType.custom;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'content': content,
      'subtitle': subtitle,
      'extra_data': extraData,
      'saved_at': savedAt.millisecondsSinceEpoch,
    };
  }

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      id: map['id'] as String,
      type: FavoriteItemType.fromString(map['type'] as String),
      title: map['title'] as String,
      content: map['content'] as String,
      subtitle: map['subtitle'] as String?,
      extraData: map['extra_data'] as String?,
      savedAt: DateTime.fromMillisecondsSinceEpoch(map['saved_at'] as int),
    );
  }

  FavoriteItem copyWith({
    String? id,
    FavoriteItemType? type,
    String? title,
    String? content,
    String? subtitle,
    String? extraData,
    DateTime? savedAt,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      subtitle: subtitle ?? this.subtitle,
      extraData: extraData ?? this.extraData,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FavoriteItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
