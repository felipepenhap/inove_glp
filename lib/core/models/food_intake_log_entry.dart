class FoodIntakeLogEntry {
  const FoodIntakeLogEntry({
    required this.id,
    required this.at,
    required this.label,
    required this.proteinDeltaG,
    required this.fiberDeltaG,
    required this.carbDeltaG,
    required this.manualKcalDelta,
    required this.source,
  });

  final String id;
  final DateTime at;
  final String label;
  final double proteinDeltaG;
  final double fiberDeltaG;
  final double carbDeltaG;
  final double manualKcalDelta;
  final String source;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'label': label,
        'p': proteinDeltaG,
        'f': fiberDeltaG,
        'c': carbDeltaG,
        'kcal': manualKcalDelta,
        'src': source,
      };

  static FoodIntakeLogEntry fromJson(Map<String, dynamic> m) {
    return FoodIntakeLogEntry(
      id: (m['id'] as String?) ?? '',
      at: DateTime.tryParse((m['at'] as String?) ?? '') ?? DateTime.now(),
      label: (m['label'] as String?) ?? '',
      proteinDeltaG: ((m['p'] as num?) ?? 0).toDouble(),
      fiberDeltaG: ((m['f'] as num?) ?? 0).toDouble(),
      carbDeltaG: ((m['c'] as num?) ?? 0).toDouble(),
      manualKcalDelta: ((m['kcal'] as num?) ?? 0).toDouble(),
      source: (m['src'] as String?) ?? '',
    );
  }
}
