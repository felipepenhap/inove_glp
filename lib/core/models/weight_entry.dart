class WeightEntry {
  const WeightEntry({required this.at, required this.kg});

  final DateTime at;
  final double kg;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'kg': kg,
      };

  static WeightEntry fromJson(Map<String, dynamic> m) {
    return WeightEntry(
      at: DateTime.parse(m['at'] as String),
      kg: (m['kg'] as num).toDouble(),
    );
  }
}
