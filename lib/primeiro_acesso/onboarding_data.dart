import '../core/data/medications.dart';

class OnboardingData {
  bool usingGlp1 = true;
  String medicationLine = kMedicationLines[0];
  String doseLabel = '2.5mg';
  int frequencyDays = 7;
  String sex = 'm';
  int age = 30;
  int heightCm = 170;
  double weightCurrent = 100;
  double weightGoal = 80;
  String activityKey = 'light';
  String displayName = '';
  String email = '';
  String password = '';

  void syncDoseToMedication() {
    final d = doseLabelsForMedication(medicationLine);
    if (d.isNotEmpty) doseLabel = d.first;
  }
}
