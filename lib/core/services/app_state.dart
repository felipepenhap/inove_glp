import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/injection_log.dart';
import '../models/injection_site.dart';
import '../models/subscription_tier.dart';
import '../models/user_profile.dart';
import '../models/water_intake_entry.dart';
import '../models/weight_entry.dart';

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
const _kWaterLog = 'inove_water_log_json';
const kTermsVersion = 1;

class AppState extends ChangeNotifier {
  AppState() {
    _load();
  }

  final _uuid = const Uuid();
  bool _ready = false;
  bool get isReady => _ready;

  bool _firstAccessDone = false;
  bool get firstAccessDone => _firstAccessDone;

  UserProfile? _profile;
  UserProfile? get profile => _profile;
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

  double get waterMl => _waterMl;
  final List<WaterIntakeEntry> _waterLog = [];
  List<WaterIntakeEntry> get waterLogToday {
    final sorted = [..._waterLog]..sort((a, b) => b.at.compareTo(a.at));
    return List<WaterIntakeEntry>.unmodifiable(sorted);
  }

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

  void _bumpIntakeIfNewDay() {
    final t = _todayKey();
    if (_intakeDateKey != t) {
      _intakeDateKey = t;
      _waterMl = 0;
      _waterLog.clear();
      _proteinConsumedG = 0;
      _fiberConsumedG = 0;
      _carbConsumedG = 0;
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
      final last = _weights
          .reduce((a, b) => a.at.isAfter(b.at) ? a : b);
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
    _tier = p.getString(_kTier) == 'pro' ? SubscriptionTier.pro : SubscriptionTier.free;
    _intervalDays = p.getInt(_kInterval) ?? 7;
    if (_intervalDays < 1) _intervalDays = 7;
    final rawP = p.getString(_kProfile);
    if (rawP != null && rawP.isNotEmpty) {
      _profile = UserProfile.fromJson(
        jsonDecode(rawP) as Map<String, dynamic>,
      );
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
          _waterMl = _waterLog
              .fold<int>(0, (a, e) => a + e.ml)
              .toDouble();
        }
      } catch (_) {}
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
    }
    await p.setString(_kTier, _tier == SubscriptionTier.pro ? 'pro' : 'free');
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
    await p.setString(
      _kWaterLog,
      jsonEncode(_waterLog.map((e) => e.toJson()).toList()),
    );
  }

  static UserProfile buildNutrients(UserProfile p) {
    final lean = p.startWeightKg * 0.4;
    var prot = (lean * 1.6).clamp(60.0, 125.0);
    if (p.activityKey == 'intense') prot += 10;
    if (p.activityKey == 'sedentary') prot -= 5;
    final water = p.startWeightKg * 0.035;
    final carb = 120.0;
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
      proteinTargetG: prot,
      fiberTargetG: 30,
      waterTargetL: water,
      carbTargetG: carb,
    );
  }

  Future<void> completeOnboarding(UserProfile p, {bool acceptTerms = true}) async {
    _profile = buildNutrients(p);
    if (acceptTerms) {
      _termsAcceptedVersion = kTermsVersion;
    }
    _firstAccessDone = true;
    _intervalDays = p.frequencyDays <= 0 ? 7 : p.frequencyDays;
    if (_intervalDays > 30) _intervalDays = 30;
    if (_weights.isEmpty) {
      _weights.add(WeightEntry(at: DateTime.now(), kg: p.startWeightKg));
    }
    _bumpIntakeIfNewDay();
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
    _waterLog.add(
      WaterIntakeEntry(
        at: DateTime.now(),
        ml: d,
      ),
    );
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
        proteinTargetG: _profile!.proteinTargetG,
        fiberTargetG: _profile!.fiberTargetG,
        waterTargetL: _profile!.waterTargetL,
        carbTargetG: _profile!.carbTargetG,
      );
    }
    await _persist();
    notifyListeners();
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
