import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/training_log_entry.dart';
import '../../core/models/training_plan.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/section_header.dart';
import '../widgets/training_modality_catalog.dart';
import '../widgets/training_modality_grid.dart';
import 'pro_plan_sheet.dart';

class TreinoPage extends StatelessWidget {
  const TreinoPage({super.key});

  Future<void> _openModalityPicker(
    BuildContext context,
    AppState state, {
    required String title,
  }) async {
    var draft = List<String>.from(state.trainingPreferences);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 6,
            bottom: MediaQuery.paddingOf(ctx).bottom + 18,
          ),
          child: StatefulBuilder(
            builder: (context, setM) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.accentGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.teal.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Toque nos blocos para combinar modalidades — a ordem importa para montar sessões diferentes.',
                      style: TextStyle(
                        color: AppTheme.textMuted.withValues(alpha: 0.95),
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TrainingModalityGrid(
                      selectedKeys: draft,
                      onChanged: (v) => setM(() => draft = v),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () async {
                        await state.regenerateTrainingPlan(preferences: draft);
                        if (!context.mounted) return;
                        Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('Gerar plano IA'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  TrainingModalityDef _catalogForSession(TrainingSessionPlan s) {
    for (final m in kTrainingModalities) {
      if (m.key == s.modalityKey) {
        return m;
      }
    }
    return kTrainingModalities.last;
  }

  TrainingModalityDef _modalityDef(String k) {
    for (final m in kTrainingModalities) {
      if (m.key == k) {
        return m;
      }
    }
    return kTrainingModalities.last;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (!state.isPro) {
          return Stack(
            children: [
              _TreinoBackdrop(),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: ModernCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.navy.withValues(alpha: 0.09),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 44,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Treino Pro',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Plano IA, registro com gasto estimado e painel consolidado ficam disponíveis no plano Pro.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => showProPlanSheet(context),
                          icon: const Icon(Icons.verified_rounded),
                          label: const Text('Ativar Pro'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        final plan = state.trainingPlan;
        return Stack(
          children: [
            _TreinoBackdrop(),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      SectionHeader(
                        title: 'Centro de treino',
                        subtitle: 'Inteligência + registro corporal',
                      ),
                      if (state.shouldRemindTraining)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ModernCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEA580C).withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.notification_important_rounded,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    state.trainingLogs.isEmpty
                                        ? 'Registre seu primeiro treino para começar sua evolução.'
                                        : 'Você está há ${state.daysWithoutTraining} dias sem treino registrado. Faça uma sessão rápida hoje.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.navy,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (plan == null) ...[
                        ModernCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.hardware_rounded, color: AppTheme.teal),
                                  SizedBox(width: 8),
                                  Text(
                                    'Comece pelo motor IA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      color: AppTheme.navy,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Defina suas modalidades e gere um ciclo único conforme seus dados no app.',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => _openModalityPicker(
                                  context,
                                  state,
                                  title: 'Preferências antes do plano IA',
                                ),
                                icon: const Icon(Icons.smart_toy_outlined),
                                label: const Text('Escolher e gerar treino'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        _HeroPlanCard(
                          modalityDef: _modalityDef,
                          plan: plan,
                          preferences: state.trainingPreferences,
                          onRefresh: () => _openModalityPicker(
                            context,
                            state,
                            title: 'Regenerar com novas modalidades',
                          ),
                        ),
                        SectionHeader(
                          title: 'Painel corporativo',
                          subtitle: 'Por dia, semana, mês ou desde o primeiro registro',
                        ),
                        _TrainingOverviewCard(logs: state.trainingLogs),
                        SectionHeader(
                          title: 'Agenda inteligente',
                          subtitle: 'Sessões e detalhes do pedido atual',
                        ),
                        ...plan.sessions.map((session) {
                          final meta = _catalogForSession(session);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ModernCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          color: meta.accent.withValues(alpha: 0.14),
                                          border: Border.all(
                                            color: meta.accent.withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Icon(meta.icon, color: meta.accent, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              session.dayLabel.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.9,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                            Text(
                                              session.focus,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.timer_outlined,
                                                size: 16,
                                                color: AppTheme.textMuted,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${session.estimatedMinutes} min',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.local_fire_department_outlined,
                                                size: 16,
                                                color: AppTheme.teal,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${session.estimatedCalories} kcal',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13,
                                                  color: AppTheme.teal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Divider(height: 22, color: AppTheme.navy.withValues(alpha: 0.08)),
                                  ...session.exercises.map(
                                    (line) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Icon(
                                              Icons.chevron_right_rounded,
                                              size: 18,
                                              color: meta.accent.withValues(alpha: 0.9),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              line,
                                              style: TextStyle(
                                                height: 1.35,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.navy.withValues(alpha: 0.88),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        SectionHeader(
                          title: 'Registro rápido',
                          subtitle: 'Tempo por modalidade e kcal projetada MET',
                        ),
                        _TrainingLogCard(
                          plan: plan,
                          weightKg: state.profile?.startWeightKg ?? 80,
                          onSave: ({
                            required String activityKey,
                            required String activityLabel,
                            required String sessionTitle,
                            required int minutes,
                            required int calories,
                            required String notes,
                          }) {
                            state.addTrainingLog(
                              activityKey: activityKey,
                              activityLabel: activityLabel,
                              sessionTitle: sessionTitle,
                              durationMinutes: minutes,
                              caloriesBurned: calories,
                              notes: notes,
                            );
                          },
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TreinoBackdrop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Container(color: AppTheme.surface.withValues(alpha: 0.9)),
            Positioned(
              top: -60,
              right: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.teal.withValues(alpha: 0.22),
                      AppTheme.teal.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 140,
              left: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.navy.withValues(alpha: 0.12),
                      AppTheme.navy.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPlanCard extends StatelessWidget {
  const _HeroPlanCard({
    required this.plan,
    required this.preferences,
    required this.onRefresh,
    required this.modalityDef,
  });

  final TrainingPlan plan;
  final List<String> preferences;
  final VoidCallback onRefresh;
  final TrainingModalityDef Function(String k) modalityDef;

  @override
  Widget build(BuildContext context) {
    final chips = preferences
        .map(
          (k) {
            final def = modalityDef(k);
            return Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 6),
            child: Chip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                def.icon,
                size: 16,
                color: def.accent,
              ),
              label: Text(
                def.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: def.accent,
                  fontSize: 12,
                ),
              ),
              backgroundColor: def.accent.withValues(alpha: 0.16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: def.accent.withValues(alpha: 0.45)),
              ),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
            ),
          );
          },
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: AppTheme.brandHeaderGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.navy.withValues(alpha: 0.22),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Motor IA • plano atual',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Nova combinação e novas sessões IA',
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              ],
            ),
            Wrap(children: chips),
            const SizedBox(height: 12),
            Row(
              children: [
                _heroStat(
                  Icons.layers_rounded,
                  '${plan.sessionsPerWeek}× semana',
                  'frequência',
                ),
                const SizedBox(width: 10),
                _heroStat(
                  Icons.monitor_heart_outlined,
                  '${plan.estimatedWeeksToGoal} sem',
                  'previsão',
                ),
                const SizedBox(width: 10),
                _heroStat(
                  Icons.bolt_rounded,
                  '${plan.averageSessionMinutes}\'',
                  'médio',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${plan.averageSessionCalories} kcal média por sessão · meta semanal ${plan.weeklyCaloriesTarget} kcal',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(IconData i, String v, String s) {
    return Expanded(
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(i, color: Colors.white, size: 18),
            Text(
              v,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            Text(
              s,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.74),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingLogCard extends StatefulWidget {
  const _TrainingLogCard({
    required this.plan,
    required this.weightKg,
    required this.onSave,
  });

  final TrainingPlan plan;
  final double weightKg;
  final void Function({
    required String activityKey,
    required String activityLabel,
    required String sessionTitle,
    required int minutes,
    required int calories,
    required String notes,
  }) onSave;

  @override
  State<_TrainingLogCard> createState() => _TrainingLogCardState();
}

class _TrainingLogCardState extends State<_TrainingLogCard> {
  String _mode = 'suggested';
  int _suggestedIndex = 0;
  String _activity = 'running';
  final _minutesController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.plan.sessions.first;
    _activity = s.modalityKey;
    _minutesController.text = s.estimatedMinutes.toString();
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _met {
    return switch (_activity) {
      'running' => 9.8,
      'walking' => 4.2,
      'cycling' => 7.5,
      'swimming' => 8.0,
      'strength' => 5.5,
      _ => 6.0,
    };
  }

  int get _calories {
    final minutes = _effectiveMinutes;
    if (minutes <= 0) return 0;
    final hour = minutes / 60;
    return (_met * widget.weightKg * hour).round();
  }

  int get _effectiveMinutes {
    if (_mode == 'suggested') {
      return widget.plan.sessions[_suggestedIndex].estimatedMinutes;
    }
    return int.tryParse(_minutesController.text.trim()) ?? 0;
  }

  String get _activityLabel {
    return switch (_activity) {
      'running' => 'Corrida',
      'walking' => 'Caminhada',
      'cycling' => 'Bicicleta',
      'swimming' => 'Natação',
      'strength' => 'Musculação',
      _ => 'Misto',
    };
  }

  Widget _miniModalityChip(String key, IconData ic, Color c, String short) {
    final on = _activity == key;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _activity = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: on ? c.withValues(alpha: 0.18) : AppTheme.surface,
                border: Border.all(
                  color: on ? c.withValues(alpha: 0.6) : AppTheme.navy.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ic, color: on ? c : AppTheme.textMuted, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    short,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: on ? c : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TrainingModalityDef _modalityForSession(String key) {
    for (final m in kTrainingModalities) {
      if (m.key == key) {
        return m;
      }
    }
    return kTrainingModalities.last;
  }

  Widget _buildSuggestedSessionPicker(BuildContext context) {
    final sess = widget.plan.sessions[_suggestedIndex];
    final mod = _modalityForSession(sess.modalityKey);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openSuggestedSessionsSheet(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.teal.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.teal.withValues(alpha: 0.2),
                          AppTheme.teal.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sessão do plano',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.navy.withValues(alpha: 0.5),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sess.dayLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppTheme.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.navy.withValues(alpha: 0.45),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(mod.icon, color: mod.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sess.focus,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: AppTheme.navy.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: mod.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${sess.estimatedMinutes} min',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: mod.accent,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '~${sess.estimatedCalories} kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSuggestedSessionsSheet(BuildContext context) async {
    final idx = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height * 0.62;
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 32,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: h,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.layers_rounded,
                            color: AppTheme.teal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Escolher sessão',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: AppTheme.navy,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Toque para aplicar tempo e modalidade',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      itemCount: widget.plan.sessions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (ctx, i) {
                        final s = widget.plan.sessions[i];
                        final m = _modalityForSession(s.modalityKey);
                        final sel = i == _suggestedIndex;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.pop(ctx, i),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppTheme.teal.withValues(alpha: 0.1)
                                    : AppTheme.navy.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: sel
                                      ? AppTheme.teal.withValues(alpha: 0.45)
                                      : Colors.transparent,
                                  width: sel ? 1.5 : 0,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: m.accent.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(m.icon, color: m.accent),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.dayLabel,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            color: AppTheme.navy,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          s.focus,
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.35,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.navy.withValues(
                                              alpha: 0.78,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${s.estimatedMinutes} min · '
                                          '${s.estimatedCalories} kcal',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (sel)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: AppTheme.teal,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (idx != null && mounted) {
      setState(() {
        _suggestedIndex = idx;
        _activity = widget.plan.sessions[idx].modalityKey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const colors = {
      'running': Icons.directions_run_rounded,
      'walking': Icons.directions_walk_rounded,
      'cycling': Icons.pedal_bike_rounded,
      'swimming': Icons.pool_rounded,
      'strength': Icons.fitness_center_rounded,
      'mixed': Icons.sports_gymnastics_rounded,
    };
    const colMap = {
      'running': Color(0xFFE11D48),
      'walking': AppTheme.teal,
      'cycling': Color(0xFFEA580C),
      'swimming': Color(0xFF2563EB),
      'strength': Color(0xFF7C3AED),
      'mixed': AppTheme.navy,
    };
    const shorts = {
      'running': 'Corrida',
      'walking': 'Caminhada',
      'cycling': 'Bike',
      'swimming': 'Nado',
      'strength': 'Musculação',
      'mixed': 'Misto',
    };
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stacked_line_chart_rounded, color: AppTheme.teal),
              SizedBox(width: 8),
              Text(
                'Telemetria da sessão',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Theme(
            data: Theme.of(context).copyWith(
              segmentedButtonTheme: SegmentedButtonThemeData(
                style: ButtonStyle(
                  visualDensity: VisualDensity.standard,
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith((s) {
                    if (s.contains(WidgetState.selected)) {
                      return AppTheme.teal.withValues(alpha: 0.18);
                    }
                    return AppTheme.surface;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((s) {
                    if (s.contains(WidgetState.selected)) {
                      return AppTheme.navy;
                    }
                    return AppTheme.textMuted;
                  }),
                  side: WidgetStatePropertyAll(
                    BorderSide(color: AppTheme.teal.withValues(alpha: 0.28)),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'suggested',
                  label: Text('Treino sugerido'),
                  icon: Icon(Icons.auto_awesome_rounded, size: 18),
                ),
                ButtonSegment(
                  value: 'manual',
                  label: Text('Manual'),
                  icon: Icon(Icons.edit_calendar_rounded, size: 18),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
            ),
          ),
          const SizedBox(height: 14),
          if (_mode == 'suggested') _buildSuggestedSessionPicker(context)
          else
            TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.navy.withValues(alpha: 0.04),
                labelText: 'Duração (minutos)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppTheme.teal.withValues(alpha: 0.28),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppTheme.navy.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppTheme.teal.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(Icons.schedule_rounded, color: AppTheme.teal),
              ),
            ),
          const SizedBox(height: 12),
          if (_mode == 'manual') ...[
            Row(
              children: [
                _miniModalityChip('running', colors['running']!, colMap['running']!, shorts['running']!),
                _miniModalityChip('walking', colors['walking']!, colMap['walking']!, shorts['walking']!),
                _miniModalityChip('cycling', colors['cycling']!, colMap['cycling']!, shorts['cycling']!),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniModalityChip('swimming', colors['swimming']!, colMap['swimming']!, shorts['swimming']!),
                _miniModalityChip('strength', colors['strength']!, colMap['strength']!, shorts['strength']!),
                _miniModalityChip('mixed', colors['mixed']!, colMap['mixed']!, shorts['mixed']!),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ModernCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded, color: AppTheme.teal, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MET ${_met.toStringAsFixed(1)} · $_calories kcal projetadas',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppTheme.navy,
                        ),
                      ),
                      Text(
                        'Baseada no tempo e peso informado na aba perfil (${widget.weightKg.toStringAsFixed(0)} kg).',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.navy.withValues(alpha: 0.04),
              labelText: 'Observações (opcional)',
              prefixIcon:
                  const Icon(Icons.note_alt_outlined, color: AppTheme.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: AppTheme.navy.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: AppTheme.teal.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              final minutes = _effectiveMinutes;
              final calories = _calories;
              if (minutes <= 0 || calories <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe um tempo válido.')),
                );
                return;
              }
              widget.onSave(
                activityKey: _activity,
                activityLabel: _activityLabel,
                sessionTitle: _mode == 'suggested'
                    ? widget.plan.sessions[_suggestedIndex].focus
                    : _activityLabel,
                minutes: minutes,
                calories: calories,
                notes: _notesController.text.trim(),
              );
              _minutesController.clear();
              _notesController.clear();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Treino gravado')),
              );
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('Salvar sessão'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }
}

class _TrainingOverviewCard extends StatefulWidget {
  const _TrainingOverviewCard({required this.logs});

  final List<TrainingLogEntry> logs;

  @override
  State<_TrainingOverviewCard> createState() => _TrainingOverviewCardState();
}

class _TrainingOverviewCardState extends State<_TrainingOverviewCard> {
  String _range = 'week';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filtered = widget.logs.where((entry) {
      if (_range == 'all') return true;
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      final today = DateTime(now.year, now.month, now.day);
      if (_range == 'day') {
        return entryDate == today;
      }
      if (_range == 'week') {
        return today.difference(entryDate).inDays <= 6;
      }
      return entryDate.year == today.year && entryDate.month == today.month;
    }).toList();

    final sessions = filtered.length;
    final minutes = filtered.fold<int>(0, (acc, item) => acc + item.durationMinutes);
    final calories = filtered.fold<int>(0, (acc, item) => acc + item.caloriesBurned);
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard_customize_rounded, color: AppTheme.navy),
              SizedBox(width: 8),
              Text(
                'Painel corporativo',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'day',
                label: Text('Dia'),
                icon: Icon(Icons.wb_sunny_outlined, size: 16),
              ),
              ButtonSegment(
                value: 'week',
                label: Text('7d'),
                icon: Icon(Icons.date_range_rounded, size: 16),
              ),
              ButtonSegment(
                value: 'month',
                label: Text('Mês'),
                icon: Icon(Icons.calendar_month_outlined, size: 16),
              ),
              ButtonSegment(
                value: 'all',
                label: Text('Δ'),
                icon: Icon(Icons.all_inclusive_rounded, size: 16),
              ),
            ],
            selected: {_range},
            onSelectionChanged: (value) => setState(() => _range = value.first),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _pulseTile(Icons.timer_outlined, 'Minutos', '$minutes', Colors.indigo),
              ),
              Expanded(
                child: _pulseTile(
                  Icons.local_fire_department_outlined,
                  'Gasto',
                  '$calories kcal',
                  AppTheme.teal,
                ),
              ),
              Expanded(
                child: _pulseTile(Icons.flash_on_rounded, 'Treinos', '$sessions', Colors.deepOrange),
              ),
            ],
          ),
          Divider(height: 28, color: AppTheme.navy.withValues(alpha: 0.08)),
          Row(
            children: [
              const Icon(Icons.timeline_rounded, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                'Histórico no período',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'Sem registros — use Registro rápido acima.',
                  style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...filtered.take(8).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: entry.notes.trim().isEmpty
                          ? null
                          : () {
                              showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Observação'),
                                  content: Text(entry.notes),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Fechar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppTheme.navy.withValues(alpha: 0.04),
                          border: Border.all(color: AppTheme.navy.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                color: _activityColor(entry.activityKey).withValues(alpha: 0.16),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                _activityIcon(entry.activityKey),
                                color: _activityColor(entry.activityKey),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.sessionTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    '${entry.activityLabel} · ${entry.durationMinutes} min · ${entry.caloriesBurned} kcal',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                  Text(
                                    _fmt(entry.date),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.navy.withValues(alpha: 0.62),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              entry.notes.trim().isEmpty
                                  ? Icons.chevron_right_rounded
                                  : Icons.sticky_note_2_outlined,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _pulseTile(IconData i, String l, String v, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: c.withValues(alpha: 0.08),
          border: Border.all(color: c.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(i, size: 22, color: c),
            const SizedBox(height: 16),
            Text(
              v,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: c),
            ),
            Text(l, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  IconData _activityIcon(String key) {
    return switch (key) {
      'running' => Icons.directions_run_rounded,
      'walking' => Icons.directions_walk_rounded,
      'cycling' => Icons.pedal_bike_rounded,
      'swimming' => Icons.pool_rounded,
      'strength' => Icons.fitness_center_rounded,
      _ => Icons.sports_gymnastics_rounded,
    };
  }

  Color _activityColor(String key) {
    return switch (key) {
      'running' => const Color(0xFFE11D48),
      'walking' => AppTheme.teal,
      'cycling' => const Color(0xFFEA580C),
      'swimming' => const Color(0xFF2563EB),
      'strength' => const Color(0xFF7C3AED),
      _ => AppTheme.navy,
    };
  }
}
