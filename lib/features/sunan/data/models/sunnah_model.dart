class Sunnah {
  final String title;
  final String description;
  final String evidence;
  final String category;

  Sunnah({
    required this.title,
    required this.description,
    required this.evidence,
    required this.category,
  });

  factory Sunnah.fromJson(Map<String, dynamic> json) {
    return Sunnah(
      title: json['title'] as String,
      description: json['description'] as String,
      evidence: json['evidence'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'evidence': evidence,
      'category': category,
    };
  }
}
