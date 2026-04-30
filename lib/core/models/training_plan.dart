import 'dart:convert';

class TrainingSessionPlan {
  const TrainingSessionPlan({
    required this.dayLabel,
    required this.focus,
    required this.modalityKey,
    required this.exercises,
    required this.estimatedMinutes,
    required this.estimatedCalories,
  });

  final String dayLabel;
  final String focus;
  final String modalityKey;
  final List<String> exercises;
  final int estimatedMinutes;
  final int estimatedCalories;

  Map<String, dynamic> toJson() => {
    'dayLabel': dayLabel,
    'focus': focus,
    'modalityKey': modalityKey,
    'exercises': exercises,
    'estimatedMinutes': estimatedMinutes,
    'estimatedCalories': estimatedCalories,
  };

  static TrainingSessionPlan fromJson(Map<String, dynamic> json) {
    return TrainingSessionPlan(
      dayLabel: json['dayLabel'] as String? ?? '',
      focus: json['focus'] as String? ?? '',
      modalityKey: json['modalityKey'] as String? ?? 'strength',
      exercises: (json['exercises'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 0,
      estimatedCalories: json['estimatedCalories'] as int? ?? 0,
    );
  }
}

class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.createdAt,
    required this.sessionsPerWeek,
    required this.estimatedWeeksToGoal,
    required this.estimatedDaysToGoal,
    required this.weeklyCaloriesTarget,
    required this.rationale,
    required this.sessions,
  });

  final String id;
  final DateTime createdAt;
  final int sessionsPerWeek;
  final int estimatedWeeksToGoal;
  final int estimatedDaysToGoal;
  final int weeklyCaloriesTarget;
  final List<String> rationale;
  final List<TrainingSessionPlan> sessions;

  int get averageSessionMinutes {
    if (sessions.isEmpty) return 0;
    final total = sessions.fold<int>(0, (acc, item) => acc + item.estimatedMinutes);
    return (total / sessions.length).round();
  }

  int get averageSessionCalories {
    if (sessions.isEmpty) return 0;
    final total = sessions.fold<int>(0, (acc, item) => acc + item.estimatedCalories);
    return (total / sessions.length).round();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'sessionsPerWeek': sessionsPerWeek,
    'estimatedWeeksToGoal': estimatedWeeksToGoal,
    'estimatedDaysToGoal': estimatedDaysToGoal,
    'weeklyCaloriesTarget': weeklyCaloriesTarget,
    'rationale': rationale,
    'sessions': sessions.map((e) => e.toJson()).toList(),
  };

  static TrainingPlan? fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return fromJson(map);
  }

  static TrainingPlan fromJson(Map<String, dynamic> json) {
    return TrainingPlan(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      sessionsPerWeek: json['sessionsPerWeek'] as int? ?? 0,
      estimatedWeeksToGoal: json['estimatedWeeksToGoal'] as int? ?? 0,
      estimatedDaysToGoal: json['estimatedDaysToGoal'] as int? ?? 0,
      weeklyCaloriesTarget: json['weeklyCaloriesTarget'] as int? ?? 0,
      rationale: (json['rationale'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      sessions: (json['sessions'] as List<dynamic>? ?? const [])
          .map((e) => TrainingSessionPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
