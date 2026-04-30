import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/injection_site.dart';
import '../../core/models/weight_entry.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/section_header.dart';
import '../widgets/weight_loss_chart.dart';
import '../../core/models/user_profile.dart';
import 'log_injection_sheet.dart';
import 'pro_plan_sheet.dart';

bool _dietMetasAtingidas(AppState s, UserProfile p) {
  final pt = p.proteinTargetG;
  final ft = p.fiberTargetG;
  if (pt <= 0 || ft <= 0) {
    return false;
  }
  return s.proteinConsumedG >= pt && s.fiberConsumedG >= ft;
}

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, s, _) {
        final p = s.profile;
        if (p == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final next = s.nextDoseAt;
        final now = DateTime.now();
        final wCur = s.lastRecordedWeight;
        final wInitial = p.startWeightKg;
        final dayLabel = DateFormat('EEEE, d MMM', 'pt_BR').format(now);
        final firstName = p.name.trim().isNotEmpty ? p.name.split(' ').first : 'utilizador';
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
          children: [
            const SizedBox(height: 4),
            _DashboardHeader(
              dayLabel: dayLabel,
              greeting: firstName,
              dietMetasAtingidas: _dietMetasAtingidas(s, p),
              profilePhotoPath: s.profilePhotoPath,
            ),
            const SizedBox(height: 16),
            ModernCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Próxima aplicação',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          next == null
                              ? 'A definir — registe a 1.ª aplicação'
                              : 'Prevista: ${DateFormat("dd/MM/yyyy", "pt_BR").format(next)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (next != null && s.lastInjectionAt != null)
                    Text(
                      _daysLeftLabel(next, now),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.teal,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _macroCard(
                    icon: Icons.egg_outlined,
                    successIcon: Icons.check_circle_rounded,
                    color: const Color(0xFFEA580C),
                    light: const Color(0xFFFFEDD5),
                    title: 'Proteína',
                    current: s.proteinConsumedG,
                    target: p.proteinTargetG,
                    unit: 'g',
                    dailyLabel: 'Meta hoje',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _macroCard(
                    icon: Icons.spa_outlined,
                    successIcon: Icons.check_circle_rounded,
                    color: const Color(0xFF16A34A),
                    light: const Color(0xFFDCFCE7),
                    title: 'Fibras',
                    current: s.fiberConsumedG,
                    target: p.fiberTargetG,
                    unit: 'g',
                    dailyLabel: 'Meta hoje',
                  ),
                ),
              ],
            ),
            const SectionHeader(
              title: 'Peso e evolução',
              subtitle: 'Acompanhe a sua meta e a curva de peso',
            ),
            ModernCard(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _colWeight(
                      'Inicial',
                      wInitial.toStringAsFixed(1),
                      'kg',
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: AppTheme.navy.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _colWeight(
                      'Atual',
                      wCur.toStringAsFixed(1),
                      'kg',
                      const Color(0xFFEA580C),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: AppTheme.navy.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _colWeight(
                      'Meta',
                      p.goalWeightKg.toStringAsFixed(1),
                      'kg',
                      AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
            if (wInitial > p.goalWeightKg) ...[
              const SizedBox(height: 8),
              Text(
                'Queda: ${(wInitial - wCur).clamp(0.0, 500.0).toStringAsFixed(1)} kg desde o início (registo)',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ModernCard(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.show_chart_rounded, color: AppTheme.teal, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Evolução de peso',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  WeightLossChart(entries: s.weights),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  _showRegisterWeight(context, s, wCur);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.navy.withValues(alpha: 0.06),
                  foregroundColor: AppTheme.navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.monitor_weight_outlined, color: AppTheme.teal),
                label: const Text('Registrar peso agora', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Histórico de aplicações',
              subtitle: 'Dose, local e data',
              action: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LogInjectionSheet(),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: AppTheme.teal),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Nova', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            if (s.injections.isEmpty)
              ModernCard(
                padding: const EdgeInsets.all(20),
                child: const Row(
                  children: [
                    Icon(Icons.medication_liquid_outlined, color: AppTheme.textMuted, size: 36),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Nenhuma aplicação ainda. Use o botão abaixo ou o atalho no canto.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...s.injections.take(20).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ModernCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.vaccines_rounded,
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
                                    e.doseLabel?.isNotEmpty == true
                                        ? e.doseLabel!
                                        : (s.profile?.doseLabel ?? 'Dose'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    e.site.labelKey,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yy', 'pt_BR').format(e.at),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            if (!s.isPro) ...[
              const SizedBox(height: 8),
              ModernCard(
                onTap: () => showProPlanSheet(context),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.purple, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Plano PRO — relatórios, sugestão de rotação e mais',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _daysLeftLabel(DateTime next, DateTime now) {
    final d = next.difference(now).inDays;
    if (d < 0) {
      return 'Atraso';
    }
    if (d == 0) {
      return 'Hoje';
    }
    return 'Em $d d';
  }

  Widget _colWeight(String l, String v, String unit, Color c) {
    return Column(
      children: [
        Text(
          l,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          v,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: c,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 11,
            color: c.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _macroCard({
    required IconData icon,
    required IconData successIcon,
    required Color color,
    required Color light,
    required String title,
    required double current,
    required double target,
    required String unit,
    required String dailyLabel,
  }) {
    final t = target <= 0 ? 1.0 : target;
    final reached = target > 0 && current >= target;
    return ModernCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: reached ? AppTheme.success.withValues(alpha: 0.15) : light,
                  borderRadius: BorderRadius.circular(10),
                  border: reached
                      ? Border.all(color: AppTheme.success.withValues(alpha: 0.4))
                      : null,
                ),
                child: Icon(
                  reached ? successIcon : icon,
                  size: 20,
                  color: reached ? AppTheme.success : color,
                ),
              ),
              const Spacer(),
              Text(
                reached ? 'Meta atingida' : dailyLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: reached ? AppTheme.success : AppTheme.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${current.toStringAsFixed(0)}/${target.toStringAsFixed(0)} $unit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (current / t).clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.dayLabel,
    required this.greeting,
    required this.dietMetasAtingidas,
    required this.profilePhotoPath,
  });

  final String dayLabel;
  final String greeting;
  final bool dietMetasAtingidas;
  final String? profilePhotoPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppTheme.brandHeaderGradient,
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $greeting',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (dietMetasAtingidas) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events_rounded,
                              size: 16,
                              color: Color(0xFFFDE047),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Metas de hoje concluídas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dietMetasAtingidas) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 4, right: 6),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFDE047),
                    size: 32,
                  ),
                ),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 66,
                  height: 66,
                  child: _buildHeaderPhoto(profilePhotoPath),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPhoto(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.white.withValues(alpha: 0.16),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
      );
    }
    if (kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.white.withValues(alpha: 0.16),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
          );
        },
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.white.withValues(alpha: 0.16),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
        );
      },
    );
  }
}

void _showRegisterWeight(BuildContext context, AppState s, double currentHint) {
  final c = TextEditingController(
    text: currentHint > 0 ? currentHint.toStringAsFixed(1) : '',
  );
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Registrar peso', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            labelText: 'Peso (kg)',
            hintText: 'Ex: 89,5',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final t = c.text.replaceAll(',', '.');
              final v = double.tryParse(t);
              if (v == null || v < 30 || v > 400) {
                return;
              }
              s.addWeight(WeightEntry(at: DateTime.now(), kg: v));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Peso registado.'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );
}
