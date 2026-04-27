class WaterIntakeEntry {
  const WaterIntakeEntry({
    required this.at,
    required this.ml,
  });

  final DateTime at;
  final int ml;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'ml': ml,
      };

  static WaterIntakeEntry fromJson(Map<String, dynamic> m) {
    return WaterIntakeEntry(
      at: DateTime.parse(m['at'] as String),
      ml: (m['ml'] as num).round(),
    );
  }
}
