import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/injection_log.dart';
import '../../core/models/injection_site.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/body_injection_picker.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_select_field.dart';

class LogInjectionSheet extends StatefulWidget {
  const LogInjectionSheet({super.key});

  @override
  State<LogInjectionSheet> createState() => _LogInjectionSheetState();
}

class _LogInjectionSheetState extends State<LogInjectionSheet> {
  DateTime _at = DateTime.now();
  InjectionSite _site = InjectionSite.leftAbdomen;
  final TextEditingController _doseC = TextEditingController();
  bool _doseInited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_doseInited) {
      return;
    }
    _doseInited = true;
    _doseC.text = context.read<AppState>().profile?.doseLabel ?? '';
  }

  @override
  void dispose() {
    _doseC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.94,
      minChildSize: 0.55,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Material(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.navy.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.teal.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.vaccines_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nova aplicação',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.navy,
                            height: 1.1,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Toque no corpo e confirme dose e data',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (st.suggestedNextSiteLabelPro != null) ...[
                const SizedBox(height: 12),
                ModernCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AppTheme.purple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sugestão PRO: ${st.suggestedNextSiteLabelPro!}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.navy,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Local da aplicação',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Selecione no mapa; o menu abaixo sincroniza com o toque.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              ModernCard(
                padding: const EdgeInsets.all(12),
                child: BodyInjectionPicker(
                  selected: _site,
                  onSelect: (s) {
                    setState(() {
                      _site = s;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.teal.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pin_drop_rounded,
                      size: 20,
                      color: AppTheme.teal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _site.labelKey,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Ou escolha na lista',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              ModernSelectField<InjectionSite>(
                value: _site,
                hint: 'Toque para ver todos os locais',
                fieldLabel: 'Lista de locais',
                sheetTitle: 'Local de injeção',
                leading: const Icon(
                  Icons.format_list_bulleted_rounded,
                  color: AppTheme.teal,
                  size: 22,
                ),
                items: [
                  for (final e in InjectionSite.values)
                    ModernSelectItem(
                      value: e,
                      label: e.labelKey,
                    ),
                ],
                onSelected: (e) => setState(() => _site = e),
              ),
              const SizedBox(height: 18),
              const Text(
                'Dose',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _doseC,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Ex.: 2,5 mg ou 1 mg',
                  hintText: st.profile?.doseLabel,
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.medication_liquid_outlined,
                    color: AppTheme.teal,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.navy.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.navy.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.teal,
                      width: 1.5,
                    ),
                  ),
                ),
                keyboardType: TextInputType.text,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(40),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Data e hora',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 6),
              ModernCard(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _at,
                    firstDate: DateTime.now().subtract(const Duration(days: 90)),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    builder: (ctx, c) {
                      return Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppTheme.teal,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: AppTheme.navy,
                          ),
                        ),
                        child: c!,
                      );
                    },
                  );
                  if (d == null) {
                    return;
                  }
                  if (!context.mounted) {
                    return;
                  }
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_at),
                    builder: (ctx, c) {
                      return Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppTheme.teal,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: AppTheme.navy,
                          ),
                        ),
                        child: c!,
                      );
                    },
                  );
                  if (t == null) {
                    return;
                  }
                  setState(() {
                    _at = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                  });
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.navy.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_rounded,
                      color: AppTheme.navy,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Momento do registo',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat("EEEE, dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(_at),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navy,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final doseText = _doseC.text.trim();
                  await st.addInjection(
                    InjectionLog(
                      id: const Uuid().v4(),
                      at: _at,
                      site: _site,
                      doseLabel: doseText.isEmpty ? st.profile?.doseLabel : doseText,
                    ),
                  );
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aplicação registada'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_rounded, size: 22),
                label: const Text(
                  'Registar aplicação',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
