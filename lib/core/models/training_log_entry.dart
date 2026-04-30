class TrainingLogEntry {
  const TrainingLogEntry({
    required this.id,
    required this.date,
    required this.activityKey,
    required this.activityLabel,
    required this.sessionTitle,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.notes,
  });

  final String id;
  final DateTime date;
  final String activityKey;
  final String activityLabel;
  final String sessionTitle;
  final int durationMinutes;
  final int caloriesBurned;
  final String notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'activityKey': activityKey,
    'activityLabel': activityLabel,
    'sessionTitle': sessionTitle,
    'durationMinutes': durationMinutes,
    'caloriesBurned': caloriesBurned,
    'notes': notes,
  };

  static TrainingLogEntry fromJson(Map<String, dynamic> json) {
    return TrainingLogEntry(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      activityKey: json['activityKey'] as String? ?? 'mixed',
      activityLabel: json['activityLabel'] as String? ?? 'Treino',
      sessionTitle: json['sessionTitle'] as String? ?? 'Sessão',
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      caloriesBurned: json['caloriesBurned'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
}
