import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_profile.dart';
import '../../core/models/weight_entry.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/modern_card.dart';
import 'pro_plan_sheet.dart';

class RelatoriosPage extends StatelessWidget {
  const RelatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, s, _) {
        final p = s.profile;
        final report = _AiReport.fromState(s);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Relatórios com IA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              p == null
                  ? 'Complete seu perfil para gerar recomendações personalizadas.'
                  : 'Análises automáticas usando seus dados de peso, hidratação, aplicações e metas.',
              style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (!s.isPro) ...[
              ModernCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Relatórios com IA disponíveis no PRO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ative o plano PRO para liberar relatório diário, evolução geral, insights e plano de ação inteligente.',
                      style: TextStyle(color: AppTheme.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => showProPlanSheet(context),
                      child: const Text('Ver plano PRO'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (s.isPro) ...[
              _reportHeaderCard(report: report, profile: p),
              const SizedBox(height: 12),
              _dailySummaryCard(s, report),
              const SizedBox(height: 12),
              _progressSummaryCard(report),
              const SizedBox(height: 12),
              _insightsCard(report),
              const SizedBox(height: 12),
              _actionsCard(report),
              const SizedBox(height: 12),
            ],
            if (s.isPro)
              const ListTile(
                title: Text(
                  'Plano PRO ativo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: Icon(Icons.verified, color: AppTheme.teal),
              ),
          ],
        );
      },
    );
  }
}

Widget _reportHeaderCard({
  required _AiReport report,
  required UserProfile? profile,
}) {
  return ModernCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.purple),
            SizedBox(width: 8),
            Text(
              'Resumo inteligente geral',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          report.overview,
          style: const TextStyle(color: AppTheme.navy, height: 1.45),
        ),
        if (profile != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricChip('IMC atual', profile.bmi.toStringAsFixed(1)),
              _metricChip('IMC meta', profile.bmiGoal.toStringAsFixed(1)),
              _metricChip(
                'Meta de perda',
                '${report.kgToGoal.toStringAsFixed(1)} kg',
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

Widget _dailySummaryCard(AppState s, _AiReport report) {
  final waterPct = report.waterGoalMl <= 0
      ? 0.0
      : (s.waterMl / report.waterGoalMl).clamp(0.0, 1.0).toDouble();
  final proteinPct = report.proteinGoalG <= 0
      ? 0.0
      : (s.proteinConsumedG / report.proteinGoalG).clamp(0.0, 1.0).toDouble();
  final fiberPct = report.fiberGoalG <= 0
      ? 0.0
      : (s.fiberConsumedG / report.fiberGoalG).clamp(0.0, 1.0).toDouble();
  final carbPct = report.carbGoalG <= 0
      ? 0.0
      : (s.carbConsumedG / report.carbGoalG).clamp(0.0, 1.0).toDouble();
  return ModernCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Relatório do dia',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _dailyMetricRow(
          'Água',
          '${s.waterMl.round()} ml',
          '${report.waterGoalMl.round()} ml',
          waterPct,
        ),
        _dailyMetricRow(
          'Proteína',
          '${s.proteinConsumedG.round()} g',
          '${report.proteinGoalG.round()} g',
          proteinPct,
        ),
        _dailyMetricRow(
          'Fibras',
          '${s.fiberConsumedG.round()} g',
          '${report.fiberGoalG.round()} g',
          fiberPct,
        ),
        _dailyMetricRow(
          'Carboidratos',
          '${s.carbConsumedG.round()} g',
          '${report.carbGoalG.round()} g',
          carbPct,
        ),
      ],
    ),
  );
}

Widget _progressSummaryCard(_AiReport report) {
  return ModernCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evolução geral',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metricChip(
              'Peso inicial',
              '${report.startWeight.toStringAsFixed(1)} kg',
            ),
            _metricChip(
              'Peso atual',
              '${report.currentWeight.toStringAsFixed(1)} kg',
            ),
            _metricChip(
              'Peso meta',
              '${report.goalWeight.toStringAsFixed(1)} kg',
            ),
            _metricChip(
              'Mudança total',
              '${report.totalWeightChange.toStringAsFixed(1)} kg',
            ),
            _metricChip('Aplicações', '${report.totalInjections}'),
            _metricChip(
              'Aderência aplicação',
              '${report.injectionAdherence.toStringAsFixed(0)}%',
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _insightsCard(_AiReport report) {
  return ModernCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insights da IA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...report.insights.map(
          (it) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.bolt, size: 16, color: AppTheme.purple),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(it, style: const TextStyle(height: 1.35))),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _actionsCard(_AiReport report) {
  return ModernCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plano sugerido para hoje',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...report.actionPlan.map(
          (it) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppTheme.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(it, style: const TextStyle(height: 1.35))),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _metricChip(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.navy.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.navy.withValues(alpha: 0.12)),
    ),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: AppTheme.navy),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

Widget _dailyMetricRow(
  String label,
  String current,
  String target,
  double pct,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              '$current / $target',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppTheme.navy.withValues(alpha: 0.08),
            color: AppTheme.teal,
          ),
        ),
      ],
    ),
  );
}

class _AiReport {
  _AiReport({
    required this.overview,
    required this.startWeight,
    required this.currentWeight,
    required this.goalWeight,
    required this.totalWeightChange,
    required this.kgToGoal,
    required this.totalInjections,
    required this.injectionAdherence,
    required this.waterGoalMl,
    required this.proteinGoalG,
    required this.fiberGoalG,
    required this.carbGoalG,
    required this.insights,
    required this.actionPlan,
  });

  final String overview;
  final double startWeight;
  final double currentWeight;
  final double goalWeight;
  final double totalWeightChange;
  final double kgToGoal;
  final int totalInjections;
  final double injectionAdherence;
  final double waterGoalMl;
  final double proteinGoalG;
  final double fiberGoalG;
  final double carbGoalG;
  final List<String> insights;
  final List<String> actionPlan;

  static _AiReport fromState(AppState s) {
    final p = s.profile;
    if (p == null) {
      return _AiReport(
        overview:
            'Sem dados suficientes para análise. Preencha o perfil e registre peso, aplicações e alimentação.',
        startWeight: 0,
        currentWeight: 0,
        goalWeight: 0,
        totalWeightChange: 0,
        kgToGoal: 0,
        totalInjections: 0,
        injectionAdherence: 0,
        waterGoalMl: 0,
        proteinGoalG: 0,
        fiberGoalG: 0,
        carbGoalG: 0,
        insights: const [
          'Complete seu perfil para liberar relatórios personalizados.',
        ],
        actionPlan: const [
          'Registre o peso atual e o consumo de água para iniciar o acompanhamento.',
        ],
      );
    }

    final currentWeight = s.lastRecordedWeight > 0
        ? s.lastRecordedWeight
        : p.startWeightKg;
    final totalWeightChange = currentWeight - p.startWeightKg;
    final kgToGoal = (currentWeight - p.goalWeightKg).clamp(0, 9999).toDouble();
    final daysSinceStart = s.weights.isEmpty
        ? 1
        : DateTime.now()
              .difference(s.weights.first.at)
              .inDays
              .abs()
              .clamp(1, 9999);
    final expectedInjections = (daysSinceStart / p.frequencyDays).ceil().clamp(
      1,
      9999,
    );
    final adherence = (s.injections.length / expectedInjections * 100).clamp(
      0.0,
      100.0,
    );
    final weeklyDelta = _weeklyDelta(s.weights, currentWeight);
    final hydrationPct = p.waterTargetL <= 0
        ? 0.0
        : (s.waterMl / (p.waterTargetL * 1000)).clamp(0.0, 2.0).toDouble();
    final proteinPct = p.proteinTargetG <= 0
        ? 0.0
        : (s.proteinConsumedG / p.proteinTargetG).clamp(0.0, 2.0).toDouble();
    final fiberPct = p.fiberTargetG <= 0
        ? 0.0
        : (s.fiberConsumedG / p.fiberTargetG).clamp(0.0, 2.0).toDouble();
    final carbPct = p.carbTargetG <= 0
        ? 0.0
        : (s.carbConsumedG / p.carbTargetG).clamp(0.0, 2.0).toDouble();

    final overview = _buildOverview(
      profile: p,
      currentWeight: currentWeight,
      totalWeightChange: totalWeightChange,
      kgToGoal: kgToGoal,
      weeklyDelta: weeklyDelta,
      adherence: adherence,
    );

    final insights = <String>[
      if (weeklyDelta < -0.15)
        'Seu peso está em tendência de queda (${weeklyDelta.abs().toStringAsFixed(1)} kg na semana), mantendo evolução consistente.'
      else if (weeklyDelta > 0.15)
        'Houve aumento de ${weeklyDelta.toStringAsFixed(1)} kg na semana. Ajustar hidratação, constância e registro alimentar pode ajudar.'
      else
        'Seu peso ficou estável na semana. Essa estabilidade pode ser útil para consolidar hábitos antes de nova queda.',
      'Aderência de aplicações em ${adherence.toStringAsFixed(0)}%. Manter perto de 100% melhora previsibilidade dos resultados.',
      'Hoje você está em ${(hydrationPct * 100).clamp(0, 100).toStringAsFixed(0)}% da meta de água, ${(proteinPct * 100).clamp(0, 100).toStringAsFixed(0)}% da proteína e ${(fiberPct * 100).clamp(0, 100).toStringAsFixed(0)}% das fibras.',
      if (kgToGoal > 0)
        'Faltam ${kgToGoal.toStringAsFixed(1)} kg para sua meta. O ritmo atual deve ser monitorado semanalmente.',
    ];

    final actionPlan = <String>[
      'Distribua a hidratação em 6 a 8 momentos do dia para atingir ${p.waterTargetL.toStringAsFixed(1)}L.',
      'Garanta proteína em ${{'sedentary': 3, 'light': 4, 'moderate': 4, 'intense': 5}[p.activityKey] ?? 4} refeições para alcançar ${p.proteinTargetG.toStringAsFixed(0)}g.',
      'Inclua fontes de fibra em pelo menos 2 refeições principais para bater ${p.fiberTargetG.toStringAsFixed(0)}g/dia.',
      if (carbPct < 0.75)
        'Ajuste carboidratos de qualidade para evitar queda de energia e melhorar adesão ao plano.',
      'Registre peso no mesmo horário 2-3x por semana para melhorar a leitura de tendência.',
    ];

    return _AiReport(
      overview: overview,
      startWeight: p.startWeightKg,
      currentWeight: currentWeight,
      goalWeight: p.goalWeightKg,
      totalWeightChange: totalWeightChange,
      kgToGoal: kgToGoal,
      totalInjections: s.injections.length,
      injectionAdherence: adherence,
      waterGoalMl: p.waterTargetL * 1000,
      proteinGoalG: p.proteinTargetG,
      fiberGoalG: p.fiberTargetG,
      carbGoalG: p.carbTargetG,
      insights: insights,
      actionPlan: actionPlan,
    );
  }

  static double _weeklyDelta(List<WeightEntry> weights, double currentWeight) {
    if (weights.isEmpty) return 0;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final older = weights.where((w) => w.at.isBefore(weekAgo)).toList();
    if (older.isEmpty) return 0;
    older.sort((a, b) => b.at.compareTo(a.at));
    return currentWeight - older.first.kg;
  }

  static String _buildOverview({
    required UserProfile profile,
    required double currentWeight,
    required double totalWeightChange,
    required double kgToGoal,
    required double weeklyDelta,
    required double adherence,
  }) {
    final direction = totalWeightChange <= 0 ? 'redução' : 'aumento';
    final weeklyLabel = weeklyDelta < 0
        ? 'queda semanal de ${weeklyDelta.abs().toStringAsFixed(1)} kg'
        : weeklyDelta > 0
        ? 'alta semanal de ${weeklyDelta.toStringAsFixed(1)} kg'
        : 'estabilidade semanal';
    return 'Perfil ${profile.age} anos, ${profile.heightCm} cm. Peso atual ${currentWeight.toStringAsFixed(1)} kg com $direction de ${totalWeightChange.abs().toStringAsFixed(1)} kg desde o início, $weeklyLabel e aderência de aplicações em ${adherence.toStringAsFixed(0)}%. ${kgToGoal > 0 ? 'Faltam ${kgToGoal.toStringAsFixed(1)} kg para a meta.' : 'Meta de peso atingida ou muito próxima.'}';
  }
}
