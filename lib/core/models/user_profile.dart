class UserProfile {
  const UserProfile({
    required this.usingGlp1,
    required this.medicationLine,
    required this.doseLabel,
    required this.frequencyDays,
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.startWeightKg,
    required this.goalWeightKg,
    required this.activityKey,
    required this.name,
    this.email,
    this.proteinTargetG = 0,
    this.fiberTargetG = 0,
    this.waterTargetL = 0,
    this.carbTargetG = 0,
  });

  final bool usingGlp1;
  final String medicationLine;
  final String doseLabel;
  final int frequencyDays;
  final String sex;
  final int age;
  final int heightCm;
  final double startWeightKg;
  final double goalWeightKg;
  final String activityKey;
  final String name;
  final String? email;
  final double proteinTargetG;
  final double fiberTargetG;
  final double waterTargetL;
  final double carbTargetG;

  double get bmi => startWeightKg / ((heightCm / 100) * (heightCm / 100));
  double get bmiGoal => goalWeightKg / ((heightCm / 100) * (heightCm / 100));
  double get kgToLose => startWeightKg - goalWeightKg;

  Map<String, dynamic> toJson() => {
        'usingGlp1': usingGlp1,
        'medicationLine': medicationLine,
        'doseLabel': doseLabel,
        'frequencyDays': frequencyDays,
        'sex': sex,
        'age': age,
        'heightCm': heightCm,
        'startWeightKg': startWeightKg,
        'goalWeightKg': goalWeightKg,
        'activityKey': activityKey,
        'name': name,
        'email': email,
        'proteinTargetG': proteinTargetG,
        'fiberTargetG': fiberTargetG,
        'waterTargetL': waterTargetL,
        'carbTargetG': carbTargetG,
      };

  static UserProfile? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;
    return UserProfile(
      usingGlp1: m['usingGlp1'] as bool? ?? true,
      medicationLine: m['medicationLine'] as String? ?? '',
      doseLabel: m['doseLabel'] as String? ?? '',
      frequencyDays: m['frequencyDays'] as int? ?? 7,
      sex: m['sex'] as String? ?? 'm',
      age: m['age'] as int? ?? 30,
      heightCm: m['heightCm'] as int? ?? 170,
      startWeightKg: (m['startWeightKg'] as num?)?.toDouble() ?? 80,
      goalWeightKg: (m['goalWeightKg'] as num?)?.toDouble() ?? 70,
      activityKey: m['activityKey'] as String? ?? 'light',
      name: m['name'] as String? ?? '',
      email: m['email'] as String?,
      proteinTargetG: (m['proteinTargetG'] as num?)?.toDouble() ?? 0,
      fiberTargetG: (m['fiberTargetG'] as num?)?.toDouble() ?? 30,
      waterTargetL: (m['waterTargetL'] as num?)?.toDouble() ?? 2.5,
      carbTargetG: (m['carbTargetG'] as num?)?.toDouble() ?? 0,
    );
  }
}
