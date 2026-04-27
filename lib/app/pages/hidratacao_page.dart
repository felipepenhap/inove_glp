import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';

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
        final p = (goal > 0 ? (cur * 100.0 / goal) : 0.0).clamp(0.0, 100.0);
        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HydrationGoalCard(
                  currentMl: cur,
                  goalMl: goal,
                  percent: p,
                  remainingMl: remaining,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Adicionar água',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF37474F),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.95,
                  children: [
                    for (var i = 0; i < _amounts.length; i++)
                      _AddWaterButton(
                        ml: _amounts[i],
                        isGlass: i < 3,
                        onTap: () {
                          s.addWaterMl(_amounts[i].toDouble());
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Histórico de hoje',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF37474F),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black12,
                  child: s.waterLogToday.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'Nenhum registro ainda. Toque nos botões acima.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: s.waterLogToday.length,
                          separatorBuilder: (context, index) {
                            return Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            );
                          },
                          itemBuilder: (context, index) {
                            final e = s.waterLogToday[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.water_drop,
                                color: AppTheme.hydrationTeal,
                                size: 24,
                              ),
                              title: Text(
                                '+${e.ml}ml',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: Text(
                                DateFormat('HH:mm', 'pt_BR').format(e.at),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 15,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.hydrationTipBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.hydrationTeal.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.hydrationTeal,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dica de Hidratação',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF37474F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Distribua a ingestão ao longo do dia. Uso de GLP-1 pode acompanhar náusea; água em pequenos goles costuma ser mais confortável.',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
  });

  final int currentMl;
  final int goalMl;
  final double percent;
  final int remainingMl;

  @override
  State<_HydrationGoalCard> createState() => _HydrationGoalCardState();
}

class _HydrationGoalCardState extends State<_HydrationGoalCard> with SingleTickerProviderStateMixin {
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
    final o = _complete(old);
    final n = _complete(widget);
    if (n && !o) {
      _ctrl.forward(from: 0);
    }
  }

  bool _complete(_HydrationGoalCard w) {
    return w.goalMl > 0 && w.currentMl >= w.goalMl;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = (widget.goalMl > 0 ? (widget.currentMl / widget.goalMl) : 0.0).clamp(0.0, 1.0);
    final met = _complete(widget);
    final child = met ? _buildSuccess() : _buildInProgress(ratio);
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      ),
      child: child,
    );
  }

  Widget _buildInProgress(double ratio) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppTheme.hydrationTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.currentMl}ml',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF263238),
                        ),
                      ),
                      Text(
                        'de ${widget.goalMl}ml hoje',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: AppTheme.hydrationTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${widget.percent.round()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.hydrationTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _statCol(
                    'Faltam',
                    widget.remainingMl > 0 ? '${widget.remainingMl}ml' : '—',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _statCol('Meta diária', '${widget.goalMl}ml'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Material(
      elevation: 3,
      shadowColor: AppTheme.hydrationTeal.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D9488),
              Color(0xFF2DD4BF),
              Color(0xFF34D399),
            ],
          ),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
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
            const SizedBox(height: 8),
            Text(
              'Parabéns! Hoje você completou a meta de ${widget.goalMl}ml.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Total: ${widget.currentMl}ml · ${widget.percent.round()}% do objetivo',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 1,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF263238),
          ),
        ),
      ],
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
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
                ml >= 1000 ? '${(ml / 1000).toStringAsFixed(0)}L' : '${ml}ml',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
