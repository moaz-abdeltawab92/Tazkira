class AsmaAllahItem {
  const AsmaAllahItem({
    required this.id,
    required this.name,
    required this.text,
    required this.nameTranslation,
    required this.textTranslation,
  });

  factory AsmaAllahItem.fromJson(Map<String, dynamic> json) => AsmaAllahItem(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        nameTranslation: json['name_translation'] as String? ?? '',
        text: json['text'] as String? ?? '',
        textTranslation: json['text_translation'] as String? ?? '',
      );

  final int id;
  final String name;
  final String nameTranslation;
  final String text;
  final String textTranslation;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'text': text,
        'name_translation': nameTranslation,
        'text_translation': textTranslation,
      };
}
