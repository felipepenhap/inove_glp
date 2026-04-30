import '../models/training_plan.dart';
import '../models/user_profile.dart';

class TrainingAi {
  static List<String> normalizePreferences(List<String>? raw) {
    if (raw == null || raw.isEmpty) return const ['strength'];
    final seen = <String>{};
    final out = <String>[];
    for (final e in raw) {
      final k = e.trim();
      if (k.isEmpty || seen.contains(k)) continue;
      seen.add(k);
      out.add(k);
    }
    if (out.isEmpty) return const ['strength'];
    return out;
  }

  static TrainingPlan generate({
    required UserProfile profile,
    required String id,
    required DateTime now,
    required List<String> preferredActivities,
  }) {
    final modalities = normalizePreferences(preferredActivities);
    final sessionsPerWeek = _sessionsForActivity(profile.activityKey);
    final intensityFactor = switch (profile.activityKey) {
      'sedentary' => 0.9,
      'light' => 1.0,
      'moderate' => 1.1,
      'intense' => 1.2,
      _ => 1.0,
    };
    final baseMinutes = (38 * intensityFactor).round().clamp(30, 60);
    final avgCalories = ((profile.startWeightKg * 4.2) * intensityFactor)
        .round()
        .clamp(160, 520);
    final avgModalityFactor =
        modalities.map(_activityCaloriesFactor).reduce((a, b) => a + b) / modalities.length;
    final weeklyCaloriesTarget = (avgCalories * sessionsPerWeek * avgModalityFactor).round();
    final kgToLose = (profile.startWeightKg - profile.goalWeightKg).clamp(0.0, 80.0);
    final medicationBoost = profile.usingGlp1 ? 1.25 : 1.0;
    final projectedKgPerWeek = ((weeklyCaloriesTarget / 7700) * medicationBoost + 0.18)
        .clamp(0.2, 1.2);
    final estimatedWeeks = kgToLose <= 0 ? 4 : (kgToLose / projectedKgPerWeek).ceil().clamp(4, 80);
    final estimatedDays = estimatedWeeks * 7;

    final labels = <String>[
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    final variantBase = Object.hash(
      id.hashCode,
      modalities.join(':').hashCode,
      now.millisecondsSinceEpoch,
      profile.startWeightKg.round(),
    );
    final expandedModalities = modalities.length == 1 && modalities.first == 'mixed'
        ? const ['walking', 'running', 'strength', 'cycling']
        : modalities;

    final sessions = <TrainingSessionPlan>[];
    for (var i = 0; i < sessionsPerWeek; i++) {
      final modality = expandedModalities[i % expandedModalities.length];
      final focus = _focusTitle(modality, i, sessionsPerWeek, variantBase);
      final exerciseVariant = _pickVariantIndex(variantBase, i, modality);
      final exercises = _exercisesForModality(modality, exerciseVariant);
      final caloriesFactor = _activityCaloriesFactor(modality);
      sessions.add(
        TrainingSessionPlan(
          dayLabel: labels[(i + (variantBase % 3)) % labels.length],
          focus: '$focus · ${_activityLabelPt(modality)}',
          modalityKey: modality,
          exercises: exercises,
          estimatedMinutes: (baseMinutes + (i % 2 == 0 ? 6 : -3) + ((variantBase + i) % 4))
              .clamp(25, 75),
          estimatedCalories:
              ((avgCalories + ((variantBase + i * 5) % 40) - 18) * caloriesFactor).round().clamp(
            130,
            620,
          ),
        ),
      );
    }

    return TrainingPlan(
      id: id,
      createdAt: now,
      sessionsPerWeek: sessionsPerWeek,
      estimatedWeeksToGoal: estimatedWeeks,
      estimatedDaysToGoal: estimatedDays,
      weeklyCaloriesTarget: weeklyCaloriesTarget,
      rationale: [
        'Plano com $sessionsPerWeek sessões semanais ajustadas ao seu nível de atividade.',
        'Modalidades escolhidas: ${modalities.map(_activityLabelPt).join(', ')}.',
        'A estimativa considera diferença de peso, uso de GLP-1 e gasto médio por modalidade.',
      ],
      sessions: sessions,
    );
  }

  static int _pickVariantIndex(int variantBase, int sessionIndex, String modality) {
    final n = _variantCount(modality);
    return ((variantBase ~/ 11) + modality.hashCode + sessionIndex * 19).abs() % n;
  }

  static int _variantCount(String modality) {
    final c = _tables[modality]?.length ?? _tables['mixed']!.length;
    return c.clamp(1, 32);
  }

  static String _focusTitle(String modality, int index, int sessions, int seed) {
    final pool = _focusPools[modality] ?? _focusPools['mixed']!;
    return pool[(index + seed ~/ 13) % pool.length];
  }

  static final Map<String, List<String>> _focusPools = {
    'strength': const [
      'Membros inferiores · potência',
      'Superior · empurrar',
      'Superior · puxar',
      'Corpo inteiro · densidade',
      'Pernas · hipertrofia',
      'Core · postura',
    ],
    'running': const [
      'Base aeróbia Z2',
      'Tiros curtos',
      'Tiros longos',
      'Ritmo sustentado',
      'Corrida leve · recuperação',
      'Corrida progressiva longa',
    ],
    'walking': const [
      'Caminhada rápida · inclinação',
      'Marcha rápida',
      'Intervalados em subida',
      'Ao ar livre · constante',
      'Recuperação ativa',
      'Longa baixo impacto',
    ],
    'swimming': const [
      'Crawl aeróbio',
      'Técnica de nado',
      'Perna + braçada guiada',
      'Sequência de estilos',
      'Tiros (25–50m)',
      'Resistência contínua',
    ],
    'cycling': const [
      'Zona 2 suave',
      'Intervalos forte',
      'Blocos endurance',
      'Cadência dirigida',
      'Pedal leve recuperação',
      'Terreno misto constante',
    ],
    'mixed': const [
      'Circuito misto cardio + força',
      'Dois bloques combinados',
      'Condicionamento metabólico',
      'Circuito atlético',
      'Mobilidade + watts',
      'Blend outdoor',
    ],
  };

  static List<String> _exercisesForModality(String modality, int variant) {
    final table = _tables[modality] ?? _tables['mixed']!;
    return table[variant % table.length];
  }

  static final Map<String, List<List<String>>> _tables = {
    'strength': const [
      [
        'Agachamento livre 4x8',
        'Levantamento terra romeno 3x10',
        'Afundo caminhando 3x12 perna',
        'Prancha 3x40s',
      ],
      [
        'Leg press 4x12',
        'Elevação pélvica 3x12',
        'Extensora + flexora 3x15',
        'Prancha lateral 3x30s',
      ],
      [
        'Supino barra 4x8',
        'Supino inclinado halteres 3x10',
        'Tríceps mergulhos 3x12',
        'Farmer carry 4x30m',
      ],
      [
        'Puxador frente 4x10',
        'Remada curvada cabo 4x10',
        'Face pull 3x15',
        'Rosca martelo 3x12',
      ],
    ],
    'running': const [
      ['Caminhada 6 min', '6x (2 min forte / 1 min leve)', 'Trote solto 8 min'],
      ['Trote leve 10 min', '4 tiros médios (~800m perc.)', 'Caminhada 5 min'],
      ['Corrida técnica 8x40m', 'Ritmo constante 18 min', 'Mobilidade quadris 6 min'],
      [
        'Aquecimento 8 min',
        'Morro ou rampa 8x40 s',
        'Recuperação plano 90 s entre',
      ],
    ],
    'walking': const [
      ['Caminhada rápida 32 min', 'Incline 5 min', 'Panturrilha livre 3x15'],
      ['Marcha média 8 min', '6x ritmo rápido 3 min', 'Relaxada 10 min'],
      ['Percurso livre ~40 min', 'Postura ombros 5 min', 'Core leve 6 min'],
      ['Esteira 5–8% incl. 25 min', 'Final plano 10 min', 'Alongamento 8 min'],
    ],
    'swimming': const [
      [
        'Aquenta 200 m fácil',
        '8x50 m crawl firme · descansa 30 s',
        'Desacelera 200 m',
      ],
      ['200 m com braçadeira técn.', '6x100 m braçadas variadas', 'Chute pap 8x25 m'],
      ['400 m contínuo Z2', '4x150 m descendente tempo', '100 m bem fácil'],
      ['Mobilização + pernada 150 m', '10x50 m com descanso', '150 m suave'],
    ],
    'cycling': const [
      ['Giro aquecimento 8 min', '6x (2 min forte / 2 min leve)', 'Final leve 8 min'],
      ['Z2 constante ~35 min', 'Drills perna única 2x3 min', 'Giro livre final 5 min'],
      ['3 blocos forte sustent.', 'Descanso 4 min entre', 'Relaxar 6 min'],
      ['Sprints cadência alta 10x30 s', 'Recuperação fácil', 'Mobilidade 8 min'],
    ],
    'mixed': const [
      ['Remada ergômetro 10 min', 'Kettle swing 4x15', 'Flexão ou apoio 4x12', 'Caminhada 8 min'],
      ['Bike erg 15 min', 'Agachamento goblet 3x12', 'Prancha 3x45 s', 'Alongar 6 min'],
      ['Pulo corda ou polichinelo 5 min', 'Complexo peso livre ~5 séries', 'Ritmo leve 10 min'],
      ['Nado muito suave ou aquática 200–400 m', 'Circuito sem peso 4 voltas', 'Caminhar 10 min'],
    ],
  };

  static int _sessionsForActivity(String activityKey) {
    return switch (activityKey) {
      'sedentary' => 3,
      'light' => 4,
      'moderate' => 5,
      'intense' => 6,
      _ => 4,
    };
  }

  static double _activityCaloriesFactor(String activity) {
    return switch (activity) {
      'running' => 1.25,
      'swimming' => 1.2,
      'cycling' => 1.15,
      'strength' => 1.0,
      'walking' => 0.85,
      _ => 0.95,
    };
  }

  static String _activityLabelPt(String activity) {
    return switch (activity) {
      'strength' => 'Musculação',
      'running' => 'Corrida',
      'walking' => 'Caminhada',
      'swimming' => 'Natação',
      'cycling' => 'Bicicleta',
      _ => 'Misto',
    };
  }
}
