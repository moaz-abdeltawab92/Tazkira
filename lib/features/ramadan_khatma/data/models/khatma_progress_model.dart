import 'dart:convert';

class KhatmaProgressModel {
  final int khatmaCount; // 1 or 2
  final Map<int, bool> completedJuzs; // 1-30 -> true/false
  final DateTime startDate;
  final DateTime? lastUpdated;

  KhatmaProgressModel({
    required this.khatmaCount,
    required this.completedJuzs,
    required this.startDate,
    this.lastUpdated,
  });

  // Calculate completion percentage
  double get completionPercentage {
    int totalJuzsToRead = 30 * khatmaCount;
    int completedCount = completedJuzs.values.where((v) => v).length;
    return (completedCount / totalJuzsToRead) * 100;
  }

  // Get remaining juzs
  int get remainingJuzs {
    int totalJuzsToRead = 30 * khatmaCount;
    int completedCount = completedJuzs.values.where((v) => v).length;
    return totalJuzsToRead - completedCount;
  }

  // Get total juzs count based on khatma count
  int get totalJuzs => 30 * khatmaCount;

  // Check if all juzs are completed
  bool get isCompleted {
    return completedJuzs.values.every((v) => v);
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'khatmaCount': khatmaCount,
      'completedJuzs':
          completedJuzs.map((key, value) => MapEntry(key.toString(), value)),
      'startDate': startDate.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  // From JSON
  factory KhatmaProgressModel.fromJson(Map<String, dynamic> json) {
    try {
      final khatmaCount = json['khatmaCount'] as int;

      // Validate khatma count
      if (khatmaCount != 1 && khatmaCount != 2) {
        throw FormatException('Invalid khatma count: $khatmaCount');
      }

      final completedJuzsJson = json['completedJuzs'] as Map<String, dynamic>;
      final completedJuzs = <int, bool>{};

      // Parse and validate completed juzs
      completedJuzsJson.forEach((key, value) {
        final juzNumber = int.tryParse(key);
        final maxJuzNumber = khatmaCount * 30;
        if (juzNumber != null && juzNumber >= 1 && juzNumber <= maxJuzNumber) {
          completedJuzs[juzNumber] = value as bool;
        }
      });

      // Ensure all juzs are present based on khatma count
      final totalJuzs = khatmaCount * 30;
      for (int i = 1; i <= totalJuzs; i++) {
        if (!completedJuzs.containsKey(i)) {
          completedJuzs[i] = false;
        }
      }

      return KhatmaProgressModel(
        khatmaCount: khatmaCount,
        completedJuzs: completedJuzs,
        startDate: DateTime.parse(json['startDate'] as String),
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'] as String)
            : null,
      );
    } catch (e) {
      throw FormatException('Failed to parse KhatmaProgressModel: $e');
    }
  }

  // String conversion for SharedPreferences
  String toJsonString() => jsonEncode(toJson());

  // From String
  factory KhatmaProgressModel.fromJsonString(String jsonString) {
    return KhatmaProgressModel.fromJson(jsonDecode(jsonString));
  }

  // Copy with
  KhatmaProgressModel copyWith({
    int? khatmaCount,
    Map<int, bool>? completedJuzs,
    DateTime? startDate,
    DateTime? lastUpdated,
  }) {
    return KhatmaProgressModel(
      khatmaCount: khatmaCount ?? this.khatmaCount,
      completedJuzs: completedJuzs ?? this.completedJuzs,
      startDate: startDate ?? this.startDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
