import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/data/food_presets.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_select_field.dart';
import '../widgets/section_header.dart';
import 'pro_plan_sheet.dart';

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
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            const SectionHeader(
              title: 'Hoje',
              subtitle: 'Contagem diária de macros',
            ),
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
                          'P +${f.proteinG.toStringAsFixed(0)}g · Fib +${f.fiberG.toStringAsFixed(0)}g · Carb +${f.carbG.toStringAsFixed(0)}g',
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
                        'P +${_presetEscolhido!.proteinG.toStringAsFixed(0)}g · Fib +${_presetEscolhido!.fiberG.toStringAsFixed(0)}g · Carb +${_presetEscolhido!.carbG.toStringAsFixed(0)}g',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        final f = _presetEscolhido!;
                        s.setMacroConsumed(
                          protein: s.proteinConsumedG + f.proteinG,
                          fiber: s.fiberConsumedG + f.fiberG,
                          carb: s.carbConsumedG + f.carbG,
                        );
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
                label: const Text('Adicionar manualmente (macros)', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SectionHeader(
              title: 'Ajuste fino de macros',
              subtitle: 'Toque nos círculos para somar ou subtrair',
            ),
            Row(
              children: [
                Expanded(
                  child: _MacroStepper(
                    label: 'Proteína',
                    icon: Icons.egg_outlined,
                    color: const Color(0xFFEA580C),
                    light: const Color(0xFFFFEDD5),
                    current: s.proteinConsumedG,
                    target: p.proteinTargetG,
                    max: 2000,
                    onSet: (v) => s.setMacroConsumed(protein: v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MacroStepper(
                    label: 'Carboidrato',
                    icon: Icons.lunch_dining_outlined,
                    color: const Color(0xFF4F46E5),
                    light: const Color(0xFFE0E7FF),
                    current: s.carbConsumedG,
                    target: p.carbTargetG,
                    max: 2000,
                    onSet: (v) => s.setMacroConsumed(carb: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MacroStepper(
              label: 'Fibras',
              icon: Icons.spa_outlined,
              color: const Color(0xFF16A34A),
              light: const Color(0xFFDCFCE7),
              current: s.fiberConsumedG,
              target: p.fiberTargetG,
              max: 200,
              onSet: (v) => s.setMacroConsumed(fiber: v),
            ),
            const SizedBox(height: 12),
            ModernCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined, color: AppTheme.navy, size: 28),
                title: const Text('Relatório PDF (PRO)', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Gere a partir de Configurações'),
                trailing: s.isPro
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.success)
                    : const Icon(Icons.lock_rounded, color: AppTheme.textMuted),
                onTap: () {
                  if (s.isPro) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Use Configurações → Relatórios e exportação'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    showProPlanSheet(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            ModernCard(
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.alarm_add_rounded, color: AppTheme.textMuted, size: 28),
                title: Text('Lembretes de suplementos', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('Horários (notificação local — em breve)'),
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
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Adicionar manualmente', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pC,
                  decoration: const InputDecoration(labelText: 'Proteína (g)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                ),
                TextField(
                  controller: fC,
                  decoration: const InputDecoration(labelText: 'Fibras (g)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                ),
                TextField(
                  controller: cC,
                  decoration: const InputDecoration(labelText: 'Carboidratos (g)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                double parseF(String t) {
                  final n = double.tryParse(t.replaceAll(',', '.'));
                  return n ?? 0;
                }

                final dp = parseF(pC.text);
                final df = parseF(fC.text);
                final dc = parseF(cC.text);
                s.setMacroConsumed(
                  protein: s.proteinConsumedG + dp,
                  fiber: s.fiberConsumedG + df,
                  carb: s.carbConsumedG + dc,
                );
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
        );
      },
    );
  }
}

class _MacroStepper extends StatelessWidget {
  const _MacroStepper({
    required this.label,
    required this.icon,
    required this.color,
    required this.light,
    required this.current,
    required this.target,
    required this.max,
    required this.onSet,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color light;
  final double current;
  final double target;
  final double max;
  final void Function(double) onSet;

  @override
  Widget build(BuildContext context) {
    final t = target > 0 ? target : 1.0;
    final frac = (current / t).clamp(0.0, 1.0);
    final atGoal = target > 0 && current >= target;
    return ModernCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: atGoal ? AppTheme.success.withValues(alpha: 0.12) : light,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  atGoal ? Icons.check_rounded : icon,
                  size: 22,
                  color: atGoal ? AppTheme.success : color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                current.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: atGoal ? AppTheme.success : AppTheme.navy,
                  height: 1,
                ),
              ),
              Text(
                ' / ${target.toStringAsFixed(0)} g',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            atGoal ? 'Meta atingida' : '${(frac * 100).round()}% da meta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: atGoal ? AppTheme.success : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (current / t).clamp(0.0, 1.0),
              minHeight: 8,
              color: atGoal ? AppTheme.success : color,
              backgroundColor: (atGoal ? AppTheme.success : color).withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stepChip(-10, onSet, current, max),
              const SizedBox(width: 4),
              _stepChip(-5, onSet, current, max),
              const SizedBox(width: 6),
              _stepChip(5, onSet, current, max),
              const SizedBox(width: 4),
              _stepChip(10, onSet, current, max),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepChip(
    int delta,
    void Function(double) onSet,
    double current,
    double cap,
  ) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            onSet((current + delta).clamp(0, cap).toDouble());
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                delta > 0 ? '+$delta' : '$delta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
