class PodcastItem {
  final String title;
  final String url;
  final String imagePath;

  const PodcastItem({
    required this.title,
    required this.url,
    required this.imagePath,
  });

  factory PodcastItem.fromJson(Map<String, dynamic> json) {
    return PodcastItem(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? json['image_path'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'imagePath': imagePath,
    };
  }
}

