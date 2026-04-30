import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/data/food_presets.dart';
import '../../core/models/food_intake_log_entry.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/food_scan_sheet.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_select_field.dart';
import '../widgets/section_header.dart';

class AlimentacaoPage extends StatefulWidget {
  const AlimentacaoPage({super.key});

  @override
  State<AlimentacaoPage> createState() => _AlimentacaoPageState();
}

class _AlimentacaoPageState extends State<AlimentacaoPage> {
  FoodPreset? _presetEscolhido;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, s, _) {
        final p = s.profile;
        if (p == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final kcalConsumed = s.caloriesConsumedToday;
        final kcalTarget = s.dailyCalorieTarget;
        final fromMacros = s.caloriesFromMacrosEstimate;
        final manualKcalExtras = kcalConsumed - fromMacros;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            const SectionHeader(
              title: 'Scanner com IA',
              subtitle: 'Primeiro passo para acelerar seu registro do dia',
            ),
            ModernCard(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F2847), Color(0xFF0DB9A3)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.teal.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.document_scanner_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Scanner inteligente de refeições',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tire uma foto ou descreva o prato para estimar proteína, fibras, carboidrato e kcal extras.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.navy,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text(
                        'Abrir scanner com IA',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      onPressed: () => showFoodScanSheet(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const SectionHeader(
              title: 'Hoje',
              subtitle: 'Calorias e macros um abaixo do outro',
            ),
            ModernCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.accentGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.teal.withValues(alpha: 0.38),
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
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${kcalConsumed.round()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              height: 1,
                            ),
                          ),
                          Text(
                            '/ ${kcalTarget.round()}',
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
                            Icon(Icons.bubble_chart_rounded, color: AppTheme.teal, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Calorias',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: kcalTarget > 0
                                ? (kcalConsumed / kcalTarget).clamp(0.0, 1.2)
                                : 0,
                            minHeight: 10,
                            color: AppTheme.teal,
                            backgroundColor: AppTheme.teal.withValues(alpha: 0.14),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          manualKcalExtras > 12
                              ? 'Macros projetam ~${fromMacros.round()} kcal '
                                  '(${manualKcalExtras.round()} kcal adicionados manualmente).'
                              : 'Projeção a partir das macros registradas (${fromMacros.round()} kcal).',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            height: 1.38,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ajustar kcal extras',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.navy.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _KcalStepChip(
                              delta: -100,
                              color: AppTheme.teal,
                              enabled: s.calorieManualExtra > 0,
                              onTap: () => s.adjustManualCalories(-100),
                            ),
                            const SizedBox(width: 6),
                            _KcalStepChip(
                              delta: -50,
                              color: AppTheme.teal,
                              enabled: s.calorieManualExtra > 0,
                              onTap: () => s.adjustManualCalories(-50),
                            ),
                            const SizedBox(width: 6),
                            _KcalStepChip(
                              delta: 50,
                              color: AppTheme.teal,
                              enabled: true,
                              onTap: () => s.adjustManualCalories(50),
                            ),
                            const SizedBox(width: 6),
                            _KcalStepChip(
                              delta: 100,
                              color: AppTheme.teal,
                              enabled: true,
                              onTap: () => s.adjustManualCalories(100),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _NutrientRingCard(
              label: 'Proteína',
              icon: Icons.egg_outlined,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEA580C), Color(0xFFF97316)],
              ),
              shadowTint: const Color(0xFFEA580C),
              barColor: const Color(0xFFEA580C),
              current: s.proteinConsumedG,
              target: p.proteinTargetG,
              max: 2000,
              onSet: (v) => s.setMacroConsumed(protein: v),
            ),
            const SizedBox(height: 10),
            _NutrientRingCard(
              label: 'Carboidrato',
              icon: Icons.lunch_dining_outlined,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
              ),
              shadowTint: const Color(0xFF4F46E5),
              barColor: const Color(0xFF4F46E5),
              current: s.carbConsumedG,
              target: p.carbTargetG,
              max: 2000,
              onSet: (v) => s.setMacroConsumed(carb: v),
            ),
            const SizedBox(height: 10),
            _NutrientRingCard(
              label: 'Fibras',
              icon: Icons.spa_outlined,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF15803D), Color(0xFF4ADE80)],
              ),
              shadowTint: const Color(0xFF16A34A),
              barColor: const Color(0xFF16A34A),
              current: s.fiberConsumedG,
              target: p.fiberTargetG,
              max: 200,
              onSet: (v) => s.setMacroConsumed(fiber: v),
            ),
            const SizedBox(height: 16),
            const SectionHeader(
              title: 'Histórico de refeições',
              subtitle:
                  'Tudo que foi somado aqui ou pelo scanner • apagar só recalcula o dia atual',
            ),
            _FoodHistoryPanel(entries: s.foodIntakeHistory),
            const SizedBox(height: 12),
            const SectionHeader(
              title: 'Comidas rápidas',
              subtitle: 'Selecione e adicione ao dia',
            ),
            ModernSelectField<FoodPreset>(
              value: _presetEscolhido,
              hint: 'Toque para escolher uma comida',
              fieldLabel: 'Comida rápida',
              sheetTitle: 'Comidas rápidas',
              leading: const Icon(
                Icons.restaurant_menu_rounded,
                color: AppTheme.teal,
                size: 24,
              ),
              allowClear: true,
              onClear: () => setState(() => _presetEscolhido = null),
              items: kFoodPresets
                  .map(
                    (f) => ModernSelectItem(
                      value: f,
                      label: f.name,
                      subtitle:
                          '≈ ${f.estimatedKcal.round()} kcal · '
                          'P +${f.proteinG.toStringAsFixed(0)}g '
                          '· Fib +${f.fiberG.toStringAsFixed(0)}g '
                          '· Carb +${f.carbG.toStringAsFixed(0)}g',
                    ),
                  )
                  .toList(),
              onSelected: (f) => setState(() => _presetEscolhido = f),
            ),
            if (_presetEscolhido != null) ...[
              const SizedBox(height: 6),
              ModernCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '≈ ${_presetEscolhido!.estimatedKcal.round()} kcal · '
                            'P +${_presetEscolhido!.proteinG.toStringAsFixed(0)}g · '
                            'Fib +${_presetEscolhido!.fiberG.toStringAsFixed(0)}g · '
                            'Carb +${_presetEscolhido!.carbG.toStringAsFixed(0)}g',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final f = _presetEscolhido!;
                        await s.recordFoodServing(
                          label: f.name,
                          proteinDeltaG: f.proteinG,
                          fiberDeltaG: f.fiberG,
                          carbDeltaG: f.carbG,
                          manualKcalDelta: 0,
                          source: 'preset',
                        );
                        if (!context.mounted) return;
                        setState(() => _presetEscolhido = null);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${f.name} adicionada'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showManualAdd(context, s),
                icon: const Icon(Icons.tune_rounded, color: AppTheme.teal),
                label: const Text(
                  'Adicionar manualmente (macros)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showManualAdd(BuildContext context, AppState s) {
    final pC = TextEditingController();
    final fC = TextEditingController();
    final cC = TextEditingController();
    final kC = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: const Color(0xFFF2F9F7),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppTheme.teal, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Adicionar manualmente',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                        fontSize: 19,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: pC,
                  decoration: const InputDecoration(
                    hintText: 'Proteína (g)',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: fC,
                  decoration: const InputDecoration(
                    hintText: 'Fibras (g)',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cC,
                  decoration: const InputDecoration(
                    hintText: 'Carboidratos (g)',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: kC,
                  decoration: const InputDecoration(
                    hintText: 'Calorias extras (kcal · opcional)',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        double parseF(String t) {
                          final n = double.tryParse(t.replaceAll(',', '.'));
                          return n ?? 0;
                        }

                        final dp = parseF(pC.text);
                        final df = parseF(fC.text);
                        final dc = parseF(cC.text);
                        final dk = parseF(kC.text);
                        await s.recordFoodServing(
                          label: 'Adição manual',
                          proteinDeltaG: dp,
                          fiberDeltaG: df,
                          carbDeltaG: dc,
                          manualKcalDelta: dk,
                          source: 'manual',
                        );
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Valores adicionados ao dia'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Somar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KcalStepChip extends StatelessWidget {
  const _KcalStepChip({
    required this.delta,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final int delta;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = delta > 0 ? '+$delta' : '$delta';
    return Expanded(
      child: Material(
        color: enabled ? color.withValues(alpha: 0.1) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: enabled ? color : AppTheme.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NutrientRingCard extends StatelessWidget {
  const _NutrientRingCard({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.shadowTint,
    required this.barColor,
    required this.current,
    required this.target,
    required this.max,
    required this.onSet,
  });

  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color shadowTint;
  final Color barColor;
  final double current;
  final double target;
  final double max;
  final void Function(double) onSet;

  @override
  Widget build(BuildContext context) {
    final t = target > 0 ? target : 1.0;
    final frac = (current / t).clamp(0.0, 1.0);
    final atGoal = target > 0 && current >= target;
    final ringColor = atGoal ? AppTheme.success : shadowTint;
    final ringGradient = atGoal
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF059669), Color(0xFF34D399)],
          )
        : gradient;
    return ModernCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ringGradient,
                  boxShadow: [
                    BoxShadow(
                      color: ringColor.withValues(alpha: 0.38),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        atGoal ? Icons.check_rounded : icon,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        current.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          height: 1,
                        ),
                      ),
                      Text(
                        '/ ${target.toStringAsFixed(0)}',
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bubble_chart_rounded,
                          color: ringColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              height: 1.2,
                              color: AppTheme.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (current / t).clamp(0.0, 1.2),
                        minHeight: 10,
                        color: atGoal ? AppTheme.success : barColor,
                        backgroundColor: (atGoal ? AppTheme.success : barColor)
                            .withValues(alpha: 0.14),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      atGoal
                          ? 'Meta atingida'
                          : '${(frac * 100).round()}% da meta diária',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            atGoal ? AppTheme.success : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MacroStepChip(
                delta: -10,
                color: barColor,
                enabled: current > 0,
                onTap: () =>
                    onSet((current - 10).clamp(0, max).toDouble()),
              ),
              const SizedBox(width: 4),
              _MacroStepChip(
                delta: -5,
                color: barColor,
                enabled: current > 0,
                onTap: () =>
                    onSet((current - 5).clamp(0, max).toDouble()),
              ),
              const SizedBox(width: 6),
              _MacroStepChip(
                delta: 5,
                color: barColor,
                enabled: current < max,
                onTap: () =>
                    onSet((current + 5).clamp(0, max).toDouble()),
              ),
              const SizedBox(width: 4),
              _MacroStepChip(
                delta: 10,
                color: barColor,
                enabled: current < max,
                onTap: () =>
                    onSet((current + 10).clamp(0, max).toDouble()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroStepChip extends StatelessWidget {
  const _MacroStepChip({
    required this.delta,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final int delta;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = delta > 0 ? '+$delta' : '$delta';
    return Expanded(
      child: Material(
        color: enabled ? color.withValues(alpha: 0.1) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: enabled ? color : AppTheme.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodHistoryPanel extends StatelessWidget {
  const _FoodHistoryPanel({required this.entries});

  final List<FoodIntakeLogEntry> entries;

  String _banner(DateTime d) {
    final n = DateTime.now();
    final d0 = DateTime(d.year, d.month, d.day);
    final t0 = DateTime(n.year, n.month, n.day);
    if (d0 == t0) {
      return 'Hoje';
    }
    final ontem = t0.subtract(const Duration(days: 1));
    if (d0.year == ontem.year && d0.month == ontem.month && d0.day == ontem.day) {
      return 'Ontem';
    }
    final f = DateFormat('EEE d/MM', 'pt_BR');
    return f.format(d);
  }

  String _sourceBr(String src) => switch (src) {
        'preset' => 'Rápida',
        'manual' => 'Manual',
        'vision_ai' => 'IA foto',
        'vision_estimate' => 'IA estimativa',
        'manual_scan' => 'Scanner',
        String() => 'Registro',
      };

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return ModernCard(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        child: Center(
          child: Text(
            'Nada registrado nesta lista ainda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    final byDay = <DateTime, List<FoodIntakeLogEntry>>{};
    for (final e in entries) {
      final k = DateTime(e.at.year, e.at.month, e.at.day);
      (byDay[k] ??= []).add(e);
    }
    final keys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final rows = <Widget>[];
    for (final k in keys) {
      final list = [...byDay[k]!]..sort((a, b) => b.at.compareTo(a.at));
      rows.add(
        Padding(
          padding: EdgeInsets.only(
            left: 2,
            right: 2,
            bottom: rows.isEmpty ? 6 : 10,
          ),
          child: Text(
            _banner(k),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: AppTheme.navy.withValues(alpha: 0.72),
            ),
          ),
        ),
      );
      for (var j = 0; j < list.length; j++) {
        rows.add(_FoodHistTile(entry: list[j], banner: _sourceBr(list[j].source)));
        if (j < list.length - 1) {
          rows.add(Divider(height: 1, color: Colors.grey.shade100));
        }
      }
      rows.add(SizedBox(height: keys.last == k ? 0 : 8));
    }
    return ModernCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }
}

class _FoodHistTile extends StatelessWidget {
  const _FoodHistTile({required this.entry, required this.banner});

  final FoodIntakeLogEntry entry;
  final String banner;

  Future<void> _remove(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remover este registro?'),
        content: Text(
          'Somente valores contados neste mesmo dia (${DateFormat('HH:mm', 'pt_BR').format(entry.at)}) são descontados automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.teal),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AppState>().removeFoodIntakeLog(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kk = entry.manualKcalDelta.round();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(
        backgroundColor: AppTheme.teal.withValues(alpha: 0.14),
        child:
            const Icon(Icons.restaurant_rounded, color: AppTheme.teal, size: 20),
      ),
      title: Text(
        entry.label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: AppTheme.navy,
        ),
      ),
      subtitle: Text(
        'P ${entry.proteinDeltaG.round()} · Fib ${entry.fiberDeltaG.round()} · Carb ${entry.carbDeltaG.round()}'
        '${kk > 0 ? ' · Extras +$kk kcal' : ''} · $banner · ${DateFormat('HH:mm', 'pt_BR').format(entry.at)}',
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textMuted,
          height: 1.35,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade500),
        onPressed: () => _remove(context),
      ),
    );
  }
}
