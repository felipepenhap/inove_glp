class WaterIntakeEntry {
  const WaterIntakeEntry({
    required this.id,
    required this.at,
    required this.ml,
  });

  final String id;
  final DateTime at;
  final int ml;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'ml': ml,
      };

  static WaterIntakeEntry fromJson(Map<String, dynamic> m) {
    final at = DateTime.parse(m['at'] as String);
    final ml = (m['ml'] as num).round();
    final id = (m['id'] as String?) ?? 'legacy_${at.toIso8601String()}_$ml';
    return WaterIntakeEntry(
      id: id,
      at: at,
      ml: ml,
    );
  }
}
