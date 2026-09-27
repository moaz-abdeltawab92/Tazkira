enum FavoriteItemType {
  azkar('ذكر', ''),
  doaa('دعاء', ''),
  hadith('حديث', ''),
  sunan('سنة نبوية', ''),
  tasbeeh('ذكر السبحة', ''),
  asma('اسم الله', ''),
  podcast('بودكاست', ''),
  custom('مخصص', '');

  const FavoriteItemType(this.label, this.emoji);

  final String label;
  final String emoji;

  static FavoriteItemType fromString(String value) {
    return FavoriteItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FavoriteItemType.custom,
    );
  }
}
