import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/injection_log.dart';
import '../models/injection_site.dart';
import '../models/subscription_tier.dart';
import '../models/training_log_entry.dart';
import '../models/food_intake_log_entry.dart';
import '../models/training_plan.dart';
import '../models/user_profile.dart';
import '../models/water_intake_entry.dart';
import '../models/weight_entry.dart';
import 'training_ai.dart';

const _kFirstAccess = 'inove_first_access_done';
const _kProfile = 'inove_user_profile_v2';
const _kTier = 'inove_subscription_tier';
const _kInjections = 'inove_injections_json';
const _kWeights = 'inove_weight_json';
const _kTermsV = 'inove_terms_version';
const _kInterval = 'inove_interval_days';
const _kDayKey = 'inove_intake_date';
const _kWaterMl = 'inove_water_ml';
const _kProteinG = 'inove_protein_g';
const _kFiberG = 'inove_fiber_g';
const _kCarbG = 'inove_carb_g';
const _kCalorieExtra = 'inove_calorie_extra_g';
const _kWaterLog = 'inove_water_log_json';
const _kFoodHist = 'inove_food_intake_hist_json';
const _kReminderDoseEnabled = 'inove_reminder_dose_enabled';
const _kReminderDoseHour = 'inove_reminder_dose_hour';
const _kReminderDoseMinute = 'inove_reminder_dose_minute';
const _kReminderHydrationEnabled = 'inove_reminder_hydration_enabled';
const _kReminderHydrationIntervalMin = 'inove_reminder_hydration_interval_min';
const _kReminderWeightEnabled = 'inove_reminder_weight_enabled';
const _kReminderWeightHour = 'inove_reminder_weight_hour';
const _kReminderWeightMinute = 'inove_reminder_weight_minute';
const _kReminderMealEnabled = 'inove_reminder_meal_enabled';
const _kReminderMealHour = 'inove_reminder_meal_hour';
const _kReminderMealMinute = 'inove_reminder_meal_minute';
const _kReminderTrainingEnabled = 'inove_reminder_training_enabled';
const _kReminderTrainingHour = 'inove_reminder_training_hour';
const _kReminderTrainingMinute = 'inove_reminder_training_minute';
const _kSessionLoggedIn = 'inove_session_logged_in';
const _kRememberLogin = 'inove_remember_login';
const _kProfilePhotoPath = 'inove_profile_photo_path';
const _kTrainingPlan = 'inove_training_plan_json';
const _kTrainingLog = 'inove_training_log_json';
const _kTrainingPreferences = 'inove_training_preferences_json';
const kTermsVersion = 1;

bool profileHasLinkedAccount(UserProfile? p) {
  if (p == null) return false;
  final e = (p.email ?? '').trim();
  final pw = (p.password ?? '').trim();
  return e.isNotEmpty && pw.isNotEmpty;
}

class AppState extends ChangeNotifier {
  AppState() {
    _load();
  }

  final _uuid = const Uuid();
  bool _ready = false;
  bool get isReady => _ready;

  bool _firstAccessDone = false;
  bool get firstAccessDone => _firstAccessDone;
  bool _loggedIn = false;
  bool get isLoggedIn => _loggedIn;
  bool _rememberLogin = true;
  bool get rememberLogin => _rememberLogin;

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  String? _profilePhotoPath;
  String? get profilePhotoPath => _profilePhotoPath;
  int _termsAcceptedVersion = 0;

  SubscriptionTier _tier = SubscriptionTier.free;
  SubscriptionTier get tier => _tier;
  bool get isPro => _tier == SubscriptionTier.pro;

  final List<InjectionLog> _injections = [];
  List<InjectionLog> get injections {
    final sorted = [..._injections]..sort((a, b) => b.at.compareTo(a.at));
    return List<InjectionLog>.unmodifiable(sorted);
  }

  final List<WeightEntry> _weights = [];
  List<WeightEntry> get weights {
    final sorted = [..._weights]..sort((a, b) => a.at.compareTo(b.at));
    return List<WeightEntry>.unmodifiable(sorted);
  }

  int _intervalDays = 7;
  int get intervalDays => _intervalDays;

  String? _intakeDateKey;
  double _waterMl = 0;
  double _proteinConsumedG = 0;
  double _fiberConsumedG = 0;
  double _carbConsumedG = 0;
  double _calorieManualExtra = 0;

  double get waterMl => _waterMl;
  final List<WaterIntakeEntry> _waterLog = [];
  List<WaterIntakeEntry> get waterLogToday {
    final sorted = [..._waterLog]..sort((a, b) => b.at.compareTo(a.at));
    return List<WaterIntakeEntry>.unmodifiable(sorted);
  }

  final List<FoodIntakeLogEntry> _foodIntakeHistory = [];
  static const _kFoodHistCap = 400;

  List<FoodIntakeLogEntry> get foodIntakeHistory {
    final sorted = [..._foodIntakeHistory]..sort((a, b) => b.at.compareTo(a.at));
    return List<FoodIntakeLogEntry>.unmodifiable(sorted);
  }

  TrainingPlan? _trainingPlan;
  TrainingPlan? get trainingPlan => _trainingPlan;
  final List<TrainingLogEntry> _trainingLogs = [];
  List<TrainingLogEntry> get trainingLogs {
    final sorted = [..._trainingLogs]..sort((a, b) => b.date.compareTo(a.date));
    return List<TrainingLogEntry>.unmodifiable(sorted);
  }

  int get trainingTotalSessions => _trainingLogs.length;
  int get trainingTotalMinutes =>
      _trainingLogs.fold<int>(0, (acc, item) => acc + item.durationMinutes);
  int get trainingTotalCalories =>
      _trainingLogs.fold<int>(0, (acc, item) => acc + item.caloriesBurned);
  List<String> _trainingPreferences = const ['strength', 'walking'];
  List<String> get trainingPreferences => List<String>.unmodifiable(_trainingPreferences);

  double get caloriesFromMacrosEstimate =>
      _proteinConsumedG * 4 + _carbConsumedG * 4 + _fiberConsumedG * 2;

  double get caloriesConsumedToday =>
      (caloriesFromMacrosEstimate + _calorieManualExtra).clamp(0, 25000);

  double get dailyCalorieTarget =>
      _profile == null ? 2000 : computeDailyCalorieTarget(_profile!).toDouble();

  int get dailyWaterGoalMl {
    final l = _profile?.waterTargetL ?? 0;
    if (l <= 0) {
      return 2500;
    }
    return (l * 1000).round();
  }

  double get proteinConsumedG => _proteinConsumedG;
  double get fiberConsumedG => _fiberConsumedG;
  double get carbConsumedG => _carbConsumedG;

  bool _doseReminderEnabled = true;
  int _doseReminderHour = 9;
  int _doseReminderMinute = 0;
  bool _hydrationReminderEnabled = true;
  int _hydrationReminderIntervalMin = 120;
  bool _weightReminderEnabled = true;
  int _weightReminderHour = 7;
  int _weightReminderMinute = 30;
  bool _mealReminderEnabled = false;
  int _mealReminderHour = 12;
  int _mealReminderMinute = 0;
  bool _trainingReminderEnabled = true;
  int _trainingReminderHour = 19;
  int _trainingReminderMinute = 0;

  bool get doseReminderEnabled => _doseReminderEnabled;
  int get doseReminderHour => _doseReminderHour;
  int get doseReminderMinute => _doseReminderMinute;
  bool get hydrationReminderEnabled => _hydrationReminderEnabled;
  int get hydrationReminderIntervalMin => _hydrationReminderIntervalMin;
  bool get weightReminderEnabled => _weightReminderEnabled;
  int get weightReminderHour => _weightReminderHour;
  int get weightReminderMinute => _weightReminderMinute;
  bool get mealReminderEnabled => _mealReminderEnabled;
  int get mealReminderHour => _mealReminderHour;
  int get mealReminderMinute => _mealReminderMinute;
  bool get trainingReminderEnabled => _trainingReminderEnabled;
  int get trainingReminderHour => _trainingReminderHour;
  int get trainingReminderMinute => _trainingReminderMinute;
  int get trainingReminderInactivityDays => 3;
  DateTime? get lastTrainingAt {
    if (_trainingLogs.isEmpty) return null;
    return _trainingLogs.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
  }
  int get daysWithoutTraining {
    final last = lastTrainingAt;
    if (last == null) return 999;
    final n = DateTime.now();
    final from = DateTime(last.year, last.month, last.day);
    final to = DateTime(n.year, n.month, n.day);
    return to.difference(from).inDays;
  }
  bool get shouldRemindTraining =>
      _trainingReminderEnabled && daysWithoutTraining >= trainingReminderInactivityDays;

  void _bumpIntakeIfNewDay() {
    final t = _todayKey();
    if (_intakeDateKey != t) {
      _intakeDateKey = t;
      _waterMl = 0;
      _waterLog.clear();
      _proteinConsumedG = 0;
      _fiberConsumedG = 0;
      _carbConsumedG = 0;
      _calorieManualExtra = 0;
    }
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  int get freeWeightWindowDays => 90;
  int get proWeightWindowDays => 365;

  double get lastRecordedWeight {
    if (_weights.isNotEmpty) {
      final last = _weights.reduce((a, b) => a.at.isAfter(b.at) ? a : b);
      return last.kg;
    }
    return _profile?.startWeightKg ?? 0;
  }

  DateTime? get lastInjectionAt {
    if (_injections.isEmpty) return null;
    return injections.map((e) => e.at).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  DateTime? get nextDoseAt {
    final last = lastInjectionAt;
    if (last == null) return null;
    return last.add(Duration(days: _intervalDays));
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _firstAccessDone = p.getBool(_kFirstAccess) ?? false;
    _termsAcceptedVersion = p.getInt(_kTermsV) ?? 0;
    _tier = p.getString(_kTier) == 'pro'
        ? SubscriptionTier.pro
        : SubscriptionTier.free;
    _loggedIn = p.getBool(_kSessionLoggedIn) ?? false;
    _rememberLogin = p.getBool(_kRememberLogin) ?? true;
    _intervalDays = p.getInt(_kInterval) ?? 7;
    if (_intervalDays < 1) _intervalDays = 7;
    final rawP = p.getString(_kProfile);
    if (rawP != null && rawP.isNotEmpty) {
      _profile = UserProfile.fromJson(jsonDecode(rawP) as Map<String, dynamic>);
    }
    _profilePhotoPath = p.getString(_kProfilePhotoPath);
    if (!profileHasLinkedAccount(_profile) || !_rememberLogin) {
      _loggedIn = false;
    }
    final inj = p.getString(_kInjections);
    if (inj != null && inj.isNotEmpty) {
      final list = (jsonDecode(inj) as List<dynamic>)
          .map((e) => InjectionLog.fromJson(e as Map<String, dynamic>))
          .toList();
      _injections
        ..clear()
        ..addAll(list);
    }
    final w = p.getString(_kWeights);
    if (w != null && w.isNotEmpty) {
      final list = (jsonDecode(w) as List<dynamic>)
          .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _weights
        ..clear()
        ..addAll(list);
    }
    _intakeDateKey = p.getString(_kDayKey);
    _waterMl = p.getDouble(_kWaterMl) ?? 0;
    _proteinConsumedG = p.getDouble(_kProteinG) ?? 0;
    _fiberConsumedG = p.getDouble(_kFiberG) ?? 0;
    _carbConsumedG = p.getDouble(_kCarbG) ?? 0;
    _calorieManualExtra = p.getDouble(_kCalorieExtra) ?? 0;
    _doseReminderEnabled = p.getBool(_kReminderDoseEnabled) ?? true;
    _doseReminderHour = (p.getInt(_kReminderDoseHour) ?? 9).clamp(0, 23);
    _doseReminderMinute = (p.getInt(_kReminderDoseMinute) ?? 0).clamp(0, 59);
    _hydrationReminderEnabled = p.getBool(_kReminderHydrationEnabled) ?? true;
    _hydrationReminderIntervalMin =
        (p.getInt(_kReminderHydrationIntervalMin) ?? 120).clamp(30, 360);
    _weightReminderEnabled = p.getBool(_kReminderWeightEnabled) ?? true;
    _weightReminderHour = (p.getInt(_kReminderWeightHour) ?? 7).clamp(0, 23);
    _weightReminderMinute = (p.getInt(_kReminderWeightMinute) ?? 30).clamp(
      0,
      59,
    );
    _mealReminderEnabled = p.getBool(_kReminderMealEnabled) ?? false;
    _mealReminderHour = (p.getInt(_kReminderMealHour) ?? 12).clamp(0, 23);
    _mealReminderMinute = (p.getInt(_kReminderMealMinute) ?? 0).clamp(0, 59);
    _trainingReminderEnabled = p.getBool(_kReminderTrainingEnabled) ?? true;
    _trainingReminderHour = (p.getInt(_kReminderTrainingHour) ?? 19).clamp(0, 23);
    _trainingReminderMinute = (p.getInt(_kReminderTrainingMinute) ?? 0).clamp(
      0,
      59,
    );
    final logRaw = p.getString(_kWaterLog);
    if (logRaw != null && logRaw.isNotEmpty) {
      try {
        final list = (jsonDecode(logRaw) as List<dynamic>)
            .map((e) => WaterIntakeEntry.fromJson(e as Map<String, dynamic>))
            .where(
              (e) =>
                  e.at.year == DateTime.now().year &&
                  e.at.month == DateTime.now().month &&
                  e.at.day == DateTime.now().day,
            )
            .toList();
        _waterLog
          ..clear()
          ..addAll(list);
        if (_waterLog.isNotEmpty) {
          _waterMl = _waterLog.fold<int>(0, (a, e) => a + e.ml).toDouble();
        }
      } catch (_) {}
    }
    final fh = p.getString(_kFoodHist);
    if (fh != null && fh.isNotEmpty) {
      try {
        final list = (jsonDecode(fh) as List<dynamic>)
            .map((e) => FoodIntakeLogEntry.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.at.compareTo(a.at));
        _foodIntakeHistory
          ..clear()
          ..addAll(list.take(_kFoodHistCap));
      } catch (_) {}
    }
    _trainingPlan = TrainingPlan.fromJsonString(p.getString(_kTrainingPlan));
    final preferencesRaw = p.getString(_kTrainingPreferences);
    if (preferencesRaw != null && preferencesRaw.isNotEmpty) {
      _trainingPreferences = TrainingAi.normalizePreferences(
        (jsonDecode(preferencesRaw) as List<dynamic>).map((e) => e.toString()).toList(),
      );
    }
    final trainingLogRaw = p.getString(_kTrainingLog);
    if (trainingLogRaw != null && trainingLogRaw.isNotEmpty) {
      final list = (jsonDecode(trainingLogRaw) as List<dynamic>)
          .map((e) => TrainingLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _trainingLogs
        ..clear()
        ..addAll(list);
    }
    _bumpIntakeIfNewDay();
    _ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kFirstAccess, _firstAccessDone);
    if (_profile != null) {
      await p.setString(_kProfile, jsonEncode(_profile!.toJson()));
    } else {
      await p.remove(_kProfile);
    }
    if (_profilePhotoPath != null && _profilePhotoPath!.trim().isNotEmpty) {
      await p.setString(_kProfilePhotoPath, _profilePhotoPath!);
    } else {
      await p.remove(_kProfilePhotoPath);
    }
    await p.setString(_kTier, _tier == SubscriptionTier.pro ? 'pro' : 'free');
    await p.setBool(_kSessionLoggedIn, _loggedIn);
    await p.setBool(_kRememberLogin, _rememberLogin);
    await p.setInt(_kInterval, _intervalDays);
    await p.setInt(_kTermsV, _termsAcceptedVersion);
    await p.setString(
      _kInjections,
      jsonEncode(_injections.map((e) => e.toJson()).toList()),
    );
    await p.setString(
      _kWeights,
      jsonEncode(_weights.map((e) => e.toJson()).toList()),
    );
    await p.setString(_kDayKey, _intakeDateKey ?? _todayKey());
    await p.setDouble(_kWaterMl, _waterMl);
    await p.setDouble(_kProteinG, _proteinConsumedG);
    await p.setDouble(_kFiberG, _fiberConsumedG);
    await p.setDouble(_kCarbG, _carbConsumedG);
    await p.setDouble(_kCalorieExtra, _calorieManualExtra);
    await p.setString(
      _kWaterLog,
      jsonEncode(_waterLog.map((e) => e.toJson()).toList()),
    );
    await p.setString(
      _kFoodHist,
      jsonEncode(
        _foodIntakeHistory.take(_kFoodHistCap).map((e) => e.toJson()).toList(),
      ),
    );
    if (_trainingPlan != null) {
      await p.setString(_kTrainingPlan, jsonEncode(_trainingPlan!.toJson()));
    } else {
      await p.remove(_kTrainingPlan);
    }
    await p.setString(
      _kTrainingLog,
      jsonEncode(_trainingLogs.map((e) => e.toJson()).toList()),
    );
    await p.setString(_kTrainingPreferences, jsonEncode(_trainingPreferences));
    await p.setBool(_kReminderDoseEnabled, _doseReminderEnabled);
    await p.setInt(_kReminderDoseHour, _doseReminderHour);
    await p.setInt(_kReminderDoseMinute, _doseReminderMinute);
    await p.setBool(_kReminderHydrationEnabled, _hydrationReminderEnabled);
    await p.setInt(
      _kReminderHydrationIntervalMin,
      _hydrationReminderIntervalMin,
    );
    await p.setBool(_kReminderWeightEnabled, _weightReminderEnabled);
    await p.setInt(_kReminderWeightHour, _weightReminderHour);
    await p.setInt(_kReminderWeightMinute, _weightReminderMinute);
    await p.setBool(_kReminderMealEnabled, _mealReminderEnabled);
    await p.setInt(_kReminderMealHour, _mealReminderHour);
    await p.setInt(_kReminderMealMinute, _mealReminderMinute);
    await p.setBool(_kReminderTrainingEnabled, _trainingReminderEnabled);
    await p.setInt(_kReminderTrainingHour, _trainingReminderHour);
    await p.setInt(_kReminderTrainingMinute, _trainingReminderMinute);
  }

  static double computeDailyCalorieTarget(UserProfile p) {
    final weight = p.startWeightKg.clamp(35.0, 300.0);
    final height = p.heightCm.clamp(120, 230).toDouble();
    final age = p.age.clamp(15, 100).toDouble();
    final isMale = p.sex == 'm';
    final activityFactor = switch (p.activityKey) {
      'sedentary' => 1.2,
      'light' => 1.37,
      'moderate' => 1.55,
      'intense' => 1.72,
      _ => 1.37,
    };

    final bmr = 10 * weight + 6.25 * height - 5 * age + (isMale ? 5.0 : -161.0);
    final tdee = bmr * activityFactor;

    final goalDiff = (p.startWeightKg - p.goalWeightKg).clamp(-30.0, 60.0);
    final calorieDelta = (goalDiff * 22).clamp(-250.0, 450.0);
    return (tdee - calorieDelta).clamp(1200.0, 3000.0);
  }

  static UserProfile buildNutrients(UserProfile p) {
    final weight = p.startWeightKg.clamp(35.0, 300.0);
    final goalDiff = (p.startWeightKg - p.goalWeightKg).clamp(-30.0, 60.0);
    final targetCalories = computeDailyCalorieTarget(p);

    var prot = (weight * 1.6).clamp(70.0, 170.0);
    if (p.activityKey == 'intense') prot += 10;
    if (p.activityKey == 'sedentary') prot -= 5;
    prot = prot.clamp(70.0, 180.0);

    final proteinCalories = prot * 4;
    final carbShare = switch (p.activityKey) {
      'sedentary' => 0.32,
      'light' => 0.36,
      'moderate' => 0.4,
      'intense' => 0.44,
      _ => 0.36,
    };
    var carb = ((targetCalories * carbShare - proteinCalories * 0.2) / 4).clamp(
      90.0,
      320.0,
    );
    if (goalDiff > 0) {
      carb -= (goalDiff * 1.2).clamp(0.0, 45.0);
    }
    carb = carb.clamp(85.0, 300.0);

    var fiber = ((targetCalories / 1000) * 14).clamp(22.0, 45.0);
    fiber += (carb / 120).clamp(0.0, 3.0);
    fiber = fiber.clamp(22.0, 48.0);

    var water = weight * 0.035;
    if (p.activityKey == 'moderate') water += 0.25;
    if (p.activityKey == 'intense') water += 0.45;
    water = water.clamp(2.1, 5.0);
    return UserProfile(
      usingGlp1: p.usingGlp1,
      medicationLine: p.medicationLine,
      doseLabel: p.doseLabel,
      frequencyDays: p.frequencyDays,
      sex: p.sex,
      age: p.age,
      heightCm: p.heightCm,
      startWeightKg: p.startWeightKg,
      goalWeightKg: p.goalWeightKg,
      activityKey: p.activityKey,
      name: p.name,
      email: p.email,
      password: p.password,
      proteinTargetG: prot,
      fiberTargetG: fiber,
      waterTargetL: water,
      carbTargetG: carb,
    );
  }

  Future<void> completeOnboarding(
    UserProfile p, {
    bool acceptTerms = true,
    List<String> trainingPreferences = const ['strength', 'walking'],
  }) async {
    _profile = buildNutrients(p);
    if (acceptTerms) {
      _termsAcceptedVersion = kTermsVersion;
    }
    _firstAccessDone = true;
    _loggedIn = true;
    _rememberLogin = profileHasLinkedAccount(_profile);
    _intervalDays = p.frequencyDays <= 0 ? 7 : p.frequencyDays;
    if (_intervalDays > 30) _intervalDays = 30;
    if (_weights.isEmpty) {
      _weights.add(WeightEntry(at: DateTime.now(), kg: p.startWeightKg));
    }
    _bumpIntakeIfNewDay();
    _trainingPreferences =
        TrainingAi.normalizePreferences(trainingPreferences);
    _trainingPlan = TrainingAi.generate(
      profile: _profile!,
      id: _uuid.v4(),
      now: DateTime.now(),
      preferredActivities: _trainingPreferences,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> regenerateTrainingPlan({List<String>? preferences}) async {
    final profile = _profile;
    if (profile == null) return;
    if (preferences != null && preferences.isNotEmpty) {
      _trainingPreferences = TrainingAi.normalizePreferences(preferences);
    }
    _trainingPlan = TrainingAi.generate(
      profile: profile,
      id: _uuid.v4(),
      now: DateTime.now(),
      preferredActivities: _trainingPreferences,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> addTrainingLog({
    required String activityKey,
    required String activityLabel,
    required String sessionTitle,
    required int durationMinutes,
    required int caloriesBurned,
    required String notes,
  }) async {
    _trainingLogs.add(
      TrainingLogEntry(
        id: _uuid.v4(),
        date: DateTime.now(),
        activityKey: activityKey,
        activityLabel: activityLabel,
        sessionTitle: sessionTitle.trim().isEmpty ? activityLabel : sessionTitle.trim(),
        durationMinutes: durationMinutes.clamp(1, 300),
        caloriesBurned: caloriesBurned.clamp(1, 2500),
        notes: notes.trim(),
      ),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> setSubscription(SubscriptionTier t) async {
    _tier = t;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTier, t == SubscriptionTier.pro ? 'pro' : 'free');
    notifyListeners();
  }

  Future<void> addInjection(InjectionLog log) async {
    _injections.add(log);
    _intervalDays = _profile?.frequencyDays.clamp(1, 30) ?? _intervalDays;
    await _persist();
    notifyListeners();
  }

  Future<void> addWeight(WeightEntry e) async {
    _weights.add(e);
    await _persist();
    notifyListeners();
  }

  Future<void> addWaterMl(double delta) async {
    _bumpIntakeIfNewDay();
    final d = delta.round();
    if (d <= 0) {
      return;
    }
    _waterMl = (_waterMl + d).clamp(0, 20000);
    _waterLog.add(WaterIntakeEntry(id: _uuid.v4(), at: DateTime.now(), ml: d));
    await _persist();
    notifyListeners();
  }

  Future<void> removeWaterIntakeEntry(String id) async {
    _bumpIntakeIfNewDay();
    final i = _waterLog.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _waterLog.removeAt(i);
    _waterMl = _waterLog.fold<int>(0, (a, e) => a + e.ml).toDouble();
    await _persist();
    notifyListeners();
  }

  Future<void> setMacroConsumed({
    double? protein,
    double? fiber,
    double? carb,
  }) async {
    _bumpIntakeIfNewDay();
    if (protein != null) _proteinConsumedG = protein.clamp(0, 2000);
    if (fiber != null) _fiberConsumedG = fiber.clamp(0, 200);
    if (carb != null) _carbConsumedG = carb.clamp(0, 2000);
    await _persist();
    notifyListeners();
  }

  double get calorieManualExtra => _calorieManualExtra;

  Future<void> addManualCalories(double kcal) async {
    final v = kcal.isFinite ? kcal.round() : 0;
    if (v <= 0) return;
    _bumpIntakeIfNewDay();
    _calorieManualExtra =
        (_calorieManualExtra + v.clamp(1, 4000)).clamp(0, 12000);
    await _persist();
    notifyListeners();
  }

  Future<void> adjustManualCalories(int delta) async {
    if (delta == 0) return;
    _bumpIntakeIfNewDay();
    _calorieManualExtra =
        (_calorieManualExtra + delta).clamp(0, 12000).toDouble();
    await _persist();
    notifyListeners();
  }

  bool _sameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> recordFoodServing({
    required String label,
    required double proteinDeltaG,
    required double fiberDeltaG,
    required double carbDeltaG,
    required double manualKcalDelta,
    required String source,
  }) async {
    _bumpIntakeIfNewDay();
    _proteinConsumedG =
        (_proteinConsumedG + proteinDeltaG).clamp(0, 2000).toDouble();
    _fiberConsumedG = (_fiberConsumedG + fiberDeltaG).clamp(0, 200).toDouble();
    _carbConsumedG = (_carbConsumedG + carbDeltaG).clamp(0, 2000).toDouble();
    if (manualKcalDelta > 0) {
      final k = manualKcalDelta.isFinite ? manualKcalDelta.round().clamp(0, 8000) : 0;
      if (k > 0) {
        _calorieManualExtra =
            (_calorieManualExtra + k).clamp(0, 12000).toDouble();
      }
    }
    _foodIntakeHistory.insert(
      0,
      FoodIntakeLogEntry(
        id: _uuid.v4(),
        at: DateTime.now(),
        label: label.trim().isEmpty ? 'Refeição' : label.trim(),
        proteinDeltaG: proteinDeltaG,
        fiberDeltaG: fiberDeltaG,
        carbDeltaG: carbDeltaG,
        manualKcalDelta:
            manualKcalDelta.isFinite ? manualKcalDelta.round().toDouble() : 0,
        source: source,
      ),
    );
    while (_foodIntakeHistory.length > _kFoodHistCap) {
      _foodIntakeHistory.removeLast();
    }
    await _persist();
    notifyListeners();
  }

  Future<void> removeFoodIntakeLog(String id) async {
    _bumpIntakeIfNewDay();
    final i = _foodIntakeHistory.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final e = _foodIntakeHistory[i];
    final n = DateTime.now();
    if (_sameCalendarDay(e.at, n)) {
      _proteinConsumedG =
          (_proteinConsumedG - e.proteinDeltaG).clamp(0, 2000).toDouble();
      _fiberConsumedG =
          (_fiberConsumedG - e.fiberDeltaG).clamp(0, 200).toDouble();
      _carbConsumedG =
          (_carbConsumedG - e.carbDeltaG).clamp(0, 2000).toDouble();
      final k = e.manualKcalDelta.round();
      if (k > 0) {
        _calorieManualExtra =
            (_calorieManualExtra - k).clamp(0, 12000).toDouble();
      }
    }
    _foodIntakeHistory.removeAt(i);
    await _persist();
    notifyListeners();
  }

  Future<void> setIntervalDays(int d) async {
    _intervalDays = d.clamp(1, 30);
    if (_profile != null) {
      _profile = UserProfile(
        usingGlp1: _profile!.usingGlp1,
        medicationLine: _profile!.medicationLine,
        doseLabel: _profile!.doseLabel,
        frequencyDays: _intervalDays,
        sex: _profile!.sex,
        age: _profile!.age,
        heightCm: _profile!.heightCm,
        startWeightKg: _profile!.startWeightKg,
        goalWeightKg: _profile!.goalWeightKg,
        activityKey: _profile!.activityKey,
        name: _profile!.name,
        email: _profile!.email,
        password: _profile!.password,
        proteinTargetG: _profile!.proteinTargetG,
        fiberTargetG: _profile!.fiberTargetG,
        waterTargetL: _profile!.waterTargetL,
        carbTargetG: _profile!.carbTargetG,
      );
    }
    await _persist();
    notifyListeners();
  }

  Future<void> updateProfile(
    UserProfile profile, {
    bool recomputeTargets = true,
  }) async {
    final next = recomputeTargets ? buildNutrients(profile) : profile;
    _profile = UserProfile(
      usingGlp1: next.usingGlp1,
      medicationLine: next.medicationLine,
      doseLabel: next.doseLabel,
      frequencyDays: next.frequencyDays,
      sex: next.sex,
      age: next.age,
      heightCm: next.heightCm,
      startWeightKg: next.startWeightKg,
      goalWeightKg: next.goalWeightKg,
      activityKey: next.activityKey,
      name: next.name,
      email: next.email,
      password: next.password,
      proteinTargetG: next.proteinTargetG,
      fiberTargetG: next.fiberTargetG,
      waterTargetL: next.waterTargetL,
      carbTargetG: next.carbTargetG,
    );
    _intervalDays = next.frequencyDays.clamp(1, 30);
    _trainingPlan = TrainingAi.generate(
      profile: _profile!,
      id: _uuid.v4(),
      now: DateTime.now(),
      preferredActivities: _trainingPreferences,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> setReminderSettings({
    bool? doseEnabled,
    int? doseHour,
    int? doseMinute,
    bool? hydrationEnabled,
    int? hydrationIntervalMin,
    bool? weightEnabled,
    int? weightHour,
    int? weightMinute,
    bool? mealEnabled,
    int? mealHour,
    int? mealMinute,
    bool? trainingEnabled,
    int? trainingHour,
    int? trainingMinute,
  }) async {
    if (doseEnabled != null) _doseReminderEnabled = doseEnabled;
    if (doseHour != null) _doseReminderHour = doseHour.clamp(0, 23);
    if (doseMinute != null) _doseReminderMinute = doseMinute.clamp(0, 59);
    if (hydrationEnabled != null) _hydrationReminderEnabled = hydrationEnabled;
    if (hydrationIntervalMin != null) {
      _hydrationReminderIntervalMin = hydrationIntervalMin.clamp(30, 360);
    }
    if (weightEnabled != null) _weightReminderEnabled = weightEnabled;
    if (weightHour != null) _weightReminderHour = weightHour.clamp(0, 23);
    if (weightMinute != null) _weightReminderMinute = weightMinute.clamp(0, 59);
    if (mealEnabled != null) _mealReminderEnabled = mealEnabled;
    if (mealHour != null) _mealReminderHour = mealHour.clamp(0, 23);
    if (mealMinute != null) _mealReminderMinute = mealMinute.clamp(0, 59);
    if (trainingEnabled != null) _trainingReminderEnabled = trainingEnabled;
    if (trainingHour != null) _trainingReminderHour = trainingHour.clamp(0, 23);
    if (trainingMinute != null) _trainingReminderMinute = trainingMinute.clamp(0, 59);
    await _persist();
    notifyListeners();
  }

  Future<void> setProfilePhotoPath(String? path) async {
    final next = path?.trim();
    _profilePhotoPath = (next == null || next.isEmpty) ? null : next;
    await _persist();
    notifyListeners();
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
    required bool remember,
  }) async {
    final p = _profile;
    if (p == null) {
      return false;
    }
    final ok =
        (p.email ?? '').trim().toLowerCase() == email.trim().toLowerCase() &&
        (p.password ?? '') == password;
    if (!ok) {
      return false;
    }
    _loggedIn = true;
    _rememberLogin = remember;
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _loggedIn = false;
    if (!profileHasLinkedAccount(_profile)) {
      await _clearAllUserData();
    } else {
      await _persist();
    }
    notifyListeners();
  }

  Future<void> startFirstAccess() async {
    if (!profileHasLinkedAccount(_profile)) {
      await _clearAllUserData();
    }
    _loggedIn = true;
    _firstAccessDone = false;
    await _persist();
    notifyListeners();
  }

  Future<void> _clearAllUserData() async {
    final p = await SharedPreferences.getInstance();
    _profile = null;
    _profilePhotoPath = null;
    _injections.clear();
    _weights.clear();
    _waterLog.clear();
    _trainingPlan = null;
    _trainingLogs.clear();
    _trainingPreferences = const ['strength', 'walking'];
    _firstAccessDone = false;
    _loggedIn = false;
    _rememberLogin = true;
    _termsAcceptedVersion = 0;
    _intervalDays = 7;
    _tier = SubscriptionTier.free;
    _intakeDateKey = null;
    _waterMl = 0;
    _proteinConsumedG = 0;
    _fiberConsumedG = 0;
    _carbConsumedG = 0;
    _calorieManualExtra = 0;
    _foodIntakeHistory.clear();
    _doseReminderEnabled = true;
    _doseReminderHour = 9;
    _doseReminderMinute = 0;
    _hydrationReminderEnabled = true;
    _hydrationReminderIntervalMin = 120;
    _weightReminderEnabled = true;
    _weightReminderHour = 7;
    _weightReminderMinute = 30;
    _mealReminderEnabled = false;
    _mealReminderHour = 12;
    _mealReminderMinute = 0;
    _trainingReminderEnabled = true;
    _trainingReminderHour = 19;
    _trainingReminderMinute = 0;
    await p.remove(_kProfile);
    await p.remove(_kProfilePhotoPath);
    await p.remove(_kInjections);
    await p.remove(_kWeights);
    await p.remove(_kFirstAccess);
    await p.remove(_kDayKey);
    await p.remove(_kWaterMl);
    await p.remove(_kProteinG);
    await p.remove(_kFiberG);
    await p.remove(_kCarbG);
    await p.remove(_kCalorieExtra);
    await p.remove(_kWaterLog);
    await p.remove(_kFoodHist);
    await p.remove(_kTermsV);
    await p.remove(_kTrainingPlan);
    await p.remove(_kTrainingLog);
    await p.remove(_kTrainingPreferences);
    await p.setBool(_kSessionLoggedIn, false);
    await p.setBool(_kRememberLogin, true);
    await p.setInt(_kInterval, 7);
    await p.setString(_kTier, 'free');
    await p.setBool(_kReminderDoseEnabled, _doseReminderEnabled);
    await p.setInt(_kReminderDoseHour, _doseReminderHour);
    await p.setInt(_kReminderDoseMinute, _doseReminderMinute);
    await p.setBool(_kReminderHydrationEnabled, _hydrationReminderEnabled);
    await p.setInt(
      _kReminderHydrationIntervalMin,
      _hydrationReminderIntervalMin,
    );
    await p.setBool(_kReminderWeightEnabled, _weightReminderEnabled);
    await p.setInt(_kReminderWeightHour, _weightReminderHour);
    await p.setInt(_kReminderWeightMinute, _weightReminderMinute);
    await p.setBool(_kReminderMealEnabled, _mealReminderEnabled);
    await p.setInt(_kReminderMealHour, _mealReminderHour);
    await p.setInt(_kReminderMealMinute, _mealReminderMinute);
    await p.setBool(_kReminderTrainingEnabled, _trainingReminderEnabled);
    await p.setInt(_kReminderTrainingHour, _trainingReminderHour);
    await p.setInt(_kReminderTrainingMinute, _trainingReminderMinute);
  }

  String? get suggestedNextSiteLabelPro {
    if (!isPro) return null;
    if (_injections.isEmpty) {
      return InjectionSite.leftAbdomen.labelKey;
    }
    final byRecency = [..._injections]..sort((a, b) => b.at.compareTo(a.at));
    final lastSite = byRecency.first.site;
    const order = <InjectionSite>[
      InjectionSite.leftAbdomen,
      InjectionSite.rightAbdomen,
      InjectionSite.upperLeftAbdomen,
      InjectionSite.upperRightAbdomen,
      InjectionSite.leftThigh,
      InjectionSite.rightThigh,
    ];
    final i = order.indexOf(lastSite);
    if (i < 0 || i >= order.length - 1) {
      return order[0].labelKey;
    }
    return order[i + 1].labelKey;
  }

  String newId() => _uuid.v4();
}
