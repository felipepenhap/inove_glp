import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/water_intake_entry.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/section_header.dart';

class HidratacaoPage extends StatelessWidget {
  const HidratacaoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.hydrationBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.hydrationBackground,
        title: const Text(
          'Hidratação',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF37474F),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: const HidratacaoTabView(),
    );
  }
}

class HidratacaoTabView extends StatelessWidget {
  const HidratacaoTabView({super.key});

  static const _amounts = <int>[100, 200, 300, 500, 750, 1000];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.hydrationBackground,
      child: Consumer<AppState>(
        builder: (context, s, _) {
          if (s.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final goal = s.dailyWaterGoalMl;
          final cur = s.waterMl.round();
          final remaining = (goal - cur) > 0 ? goal - cur : 0;
          final pct = (goal > 0 ? (cur * 100.0 / goal) : 0.0).clamp(0.0, 100.0);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            children: [
              const SectionHeader(
                title: 'Hoje',
                subtitle: 'Ingestão e meta de água',
              ),
              _HydrationGoalCard(
                currentMl: cur,
                goalMl: goal,
                percent: pct,
                remainingMl: remaining,
                metGoal: goal > 0 && cur >= goal,
              ),
              const SectionHeader(title: 'Adicionar água'),
              ModernCard(
                padding: const EdgeInsets.all(14),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.98,
                  children: [
                    for (var i = 0; i < _amounts.length; i++)
                      _AddWaterButton(
                        ml: _amounts[i],
                        isGlass: i < 3,
                        onTap: () => s.addWaterMl(_amounts[i].toDouble()),
                      ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Histórico de hoje'),
              ModernCard(
                padding: EdgeInsets.zero,
                child: s.waterLogToday.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 18,
                        ),
                        child: Center(
                          child: Text(
                            'Nenhum registro ainda. Use os volumes acima.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0;
                              i < s.waterLogToday.length;
                              i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                color: Colors.grey.shade100,
                              ),
                            _WaterLogRow(
                              entry: s.waterLogToday[i],
                              onRemoveRequested: () => _confirmRemoveEntry(
                                context,
                                s,
                                s.waterLogToday[i],
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              ModernCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.hydrationTeal.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: AppTheme.hydrationTeal,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dica',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppTheme.navy.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Distribua a ingestão ao longo do dia. Com GLP-1, pequenos goles costumam ser mais confortáveis.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _confirmRemoveEntry(
    BuildContext context,
    AppState s,
    WaterIntakeEntry e,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover registro?'),
        content: Text(
          'Excluir +${e.ml} ml registrados às '
          '${DateFormat('HH:mm', 'pt_BR').format(e.at)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.hydrationTeal,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await s.removeWaterIntakeEntry(e.id);
    }
  }
}

class _WaterLogRow extends StatelessWidget {
  const _WaterLogRow({
    required this.entry,
    required this.onRemoveRequested,
  });

  final WaterIntakeEntry entry;
  final VoidCallback onRemoveRequested;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.hydrationTeal.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.water_drop_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      title: Text(
        '+${entry.ml} ml',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: AppTheme.navy,
        ),
      ),
      subtitle: Text(
        DateFormat('HH:mm', 'pt_BR').format(entry.at),
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 13,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete_outline_rounded,
          color: Colors.grey.shade500,
        ),
        onPressed: onRemoveRequested,
      ),
    );
  }
}

class _HydrationGoalCard extends StatefulWidget {
  const _HydrationGoalCard({
    required this.currentMl,
    required this.goalMl,
    required this.percent,
    required this.remainingMl,
    required this.metGoal,
  });

  final int currentMl;
  final int goalMl;
  final double percent;
  final int remainingMl;
  final bool metGoal;

  @override
  State<_HydrationGoalCard> createState() => _HydrationGoalCardState();
}

class _HydrationGoalCardState extends State<_HydrationGoalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..value = 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _HydrationGoalCard old) {
    super.didUpdateWidget(old);
    if (widget.metGoal && !old.metGoal) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.metGoal ? _buildSuccess() : _buildProgress();
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      ),
      child: child,
    );
  }

  Widget _buildProgress() {
    final v = widget.goalMl > 0
        ? (widget.currentMl / widget.goalMl).clamp(0.0, 1.2)
        : 0.0;
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.hydrationTeal.withValues(alpha: 0.38),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.currentMl}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/ ${widget.goalMl} ml',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.bubble_chart_rounded,
                      color: AppTheme.hydrationTeal,
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Hidratação',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppTheme.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    color: AppTheme.hydrationTeal,
                    backgroundColor:
                        AppTheme.hydrationTeal.withValues(alpha: 0.14),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.remainingMl > 0
                      ? 'Faltam ${widget.remainingMl} ml · '
                          '${widget.percent.round()}% da meta'
                      : 'Meta atingida ou ultrapassada · '
                          '${widget.percent.round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D9488),
              Color(0xFF2DD4BF),
              Color(0xFF34D399),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.hydrationTeal.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.celebration_rounded,
                  color: Color(0xFFFDE047),
                  size: 36,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Meta atingida',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Hoje você completou ${widget.goalMl} ml · '
              'total ${widget.currentMl} ml.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 1,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWaterButton extends StatelessWidget {
  const _AddWaterButton({
    required this.ml,
    required this.isGlass,
    required this.onTap,
  });

  final int ml;
  final bool isGlass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.hydrationTeal.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.hydrationTeal.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isGlass
                    ? Icons.local_drink_outlined
                    : Icons.water_outlined,
                size: isGlass ? 30 : 34,
                color: AppTheme.hydrationTeal,
              ),
              const SizedBox(height: 8),
              Text(
                ml >= 1000
                    ? '${(ml / 1000).toStringAsFixed(0)} L'
                    : '$ml ml',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
