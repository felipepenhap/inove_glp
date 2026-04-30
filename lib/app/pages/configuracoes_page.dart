import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_profile.dart';
import '../../core/services/app_state.dart';
import '../../core/services/reminder_notifications.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/modern_card.dart';
import 'indicacoes_page.dart';
import 'pro_plan_sheet.dart';
import 'relatorios_page.dart';

String _profileSubtitle(UserProfile p) {
  final name = p.name.isNotEmpty ? p.name : 'Utilizador';
  final em = p.email;
  if (em != null && em.isNotEmpty) {
    return '$name · $em';
  }
  return name;
}

ImageProvider<Object>? _profileImageProvider(String? path) {
  if (path == null || path.isEmpty) {
    return null;
  }
  if (kIsWeb) {
    return NetworkImage(path);
  }
  return FileImage(File(path));
}

Widget _profilePhotoWidget(String? path) {
  if (path == null || path.isEmpty) {
    return const Icon(
      Icons.person_rounded,
      color: AppTheme.teal,
      size: 24,
    );
  }
  if (kIsWeb) {
    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, err, stack) => const Icon(
        Icons.person_rounded,
        color: AppTheme.teal,
        size: 24,
      ),
    );
  }
  return Image.file(
    File(path),
    fit: BoxFit.cover,
    errorBuilder: (context, err, stack) => const Icon(
      Icons.person_rounded,
      color: AppTheme.teal,
      size: 24,
    ),
  );
}

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
      children: [
        Consumer<AppState>(
          builder: (context, s, _) {
            final isPro = s.isPro;
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: isPro
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0F2847),
                          Color(0xFF1A4C6A),
                          Color(0xFF0DB9A3),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          AppTheme.navy.withValues(alpha: 0.07),
                        ],
                      ),
                border: Border.all(
                  color: isPro
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppTheme.navy.withValues(alpha: 0.22),
                  width: isPro ? 1 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.navy.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isPro
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppTheme.navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: isPro
                          ? null
                          : Border.all(
                              color: AppTheme.navy.withValues(alpha: 0.14),
                            ),
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: isPro ? Colors.white : AppTheme.navy,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seu plano atual',
                          style: TextStyle(
                            color: isPro
                                ? Colors.white.withValues(alpha: 0.88)
                                : AppTheme.navy.withValues(alpha: 0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPro ? 'PRO ativo' : 'Gratuito',
                          style: TextStyle(
                            color: isPro ? Colors.white : AppTheme.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPro)
                    FilledButton.tonal(
                      onPressed: () => showProPlanSheet(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Gerir'),
                    )
                  else
                    FilledButton(
                      onPressed: () => showProPlanSheet(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.teal,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: AppTheme.teal.withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Ativar PRO',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Consumer<AppState>(
          builder: (context, s, _) {
            final p = s.profile;
            return ModernCard(
              onTap: p == null
                  ? null
                  : () {
                      _showProfileSheet(context, s);
                    },
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _profilePhotoWidget(s.profilePhotoPath),
                  ),
                ),
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                  fontSize: 16,
                ),
                title: Text(
                  p == null
                      ? 'Editar perfil'
                      : 'Editar perfil de ${p.name.trim().isEmpty ? 'Utilizador' : p.name.trim().split(' ').first}',
                ),
                subtitle: Text(p == null ? '—' : _profileSubtitle(p)),
                isThreeLine:
                    p != null && (p.email != null && p.email!.isNotEmpty),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Consumer<AppState>(
          builder: (context, s, _) {
            return ModernCard(
              onTap: () {
                if (!s.isPro) {
                  showProPlanSheet(context);
                  return;
                }
                _showRemindersSheet(context, s);
              },
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppTheme.teal,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Lembretes',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Nao esquece de registrar e manter a rotina todos os dias.',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: s.isPro ? AppTheme.navy : AppTheme.teal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.isPro ? 'PRO ativo' : 'PRO',
                        style: TextStyle(
                          fontSize: 12,
                          color: s.isPro ? AppTheme.navy : AppTheme.teal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ModernCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Relatórios com IA'),
                    leading: const BackButton(),
                  ),
                  body: const RelatoriosPage(),
                ),
              ),
            );
          },
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.purple,
                size: 24,
              ),
            ),
            title: const Text(
              'Relatórios com IA',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Resumos e insights a partir dos seus dados'),
            trailing: Consumer<AppState>(
              builder: (context, s, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 12,
                      color: s.isPro ? AppTheme.navy : AppTheme.purple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.isPro ? 'PRO ativo' : 'PRO',
                      style: TextStyle(
                        fontSize: 12,
                        color: s.isPro ? AppTheme.navy : AppTheme.purple,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ModernCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Indicações'),
                    leading: const BackButton(),
                  ),
                  body: const IndicacoesPage(),
                ),
              ),
            );
          },
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _RoundIcon(
              child: Icon(
                Icons.menu_book_rounded,
                color: AppTheme.teal,
                size: 24,
              ),
            ),
            title: Text(
              'Dicas e indicações',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('Hidratação, dose, peso e mais'),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Consumer<AppState>(
          builder: (context, s, _) {
            return ModernCard(
              onTap: () async {
                await s.logout();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sessão encerrada.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _RoundIcon(
                  child: Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                ),
                title: Text(
                  'Sair',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDC2626),
                  ),
                ),
                subtitle: Text('Encerrar sessão e voltar ao login'),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: child),
    );
  }
}

void _showProfileSheet(BuildContext context, AppState s) {
  final p = s.profile;
  if (p == null) {
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.teal.withValues(alpha: 0.18),
                  backgroundImage: _profileImageProvider(s.profilePhotoPath),
                  child: s.profilePhotoPath == null || s.profilePhotoPath!.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppTheme.teal,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Perfil',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.navy.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name.isNotEmpty ? p.name : 'Utilizador',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: AppTheme.navy,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          s.isPro ? 'PRO' : 'FREE',
                          style: const TextStyle(
                            color: AppTheme.teal,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _profileField('Email', p.email != null && p.email!.isNotEmpty ? p.email! : 'Não informado'),
                  _profileField('Peso inicial / meta', '${p.startWeightKg.toStringAsFixed(1)} kg → ${p.goalWeightKg.toStringAsFixed(1)} kg'),
                  _profileField('Dose', p.doseLabel.isNotEmpty ? p.doseLabel : '—'),
                  _profileField('Periodicidade', 'A cada ${p.frequencyDays} dia(s)'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async => _pickProfilePhoto(context, s),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Alterar foto'),
                  ),
                ),
                const SizedBox(width: 8),
                if (s.profilePhotoPath != null && s.profilePhotoPath!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async => s.setProfilePhotoPath(null),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Remover'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showProfileEditSheet(context, s, p);
              },
              child: const Text('Editar dados'),
            ),
          ],
        ),
      );
    },
  );
}

Widget _profileField(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _pickReminderToTest(BuildContext navigatorContext) async {
  final kind = await showModalBottomSheet<ReminderTestKind>(
    context: navigatorContext,
    showDragHandle: true,
    builder: (c) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'Testar lembretes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.medication_liquid_rounded,
                  color: AppTheme.teal,
                ),
                title: const Text('Aplicação'),
                onTap: () => Navigator.pop(c, ReminderTestKind.application),
              ),
              ListTile(
                leading: Icon(
                  Icons.water_drop_rounded,
                  color: AppTheme.hydrationTeal,
                ),
                title: const Text('Hidratação'),
                onTap: () => Navigator.pop(c, ReminderTestKind.hydration),
              ),
              ListTile(
                leading: Icon(
                  Icons.monitor_weight_rounded,
                  color: AppTheme.navy,
                ),
                title: const Text('Pesagem'),
                onTap: () => Navigator.pop(c, ReminderTestKind.weighing),
              ),
              ListTile(
                leading: Icon(Icons.restaurant_rounded, color: AppTheme.purple),
                title: const Text('Refeição proteica'),
                onTap: () => Navigator.pop(c, ReminderTestKind.meal),
              ),
              ListTile(
                leading: Icon(Icons.fitness_center_rounded, color: AppTheme.navy),
                title: const Text('Treino (3 dias sem registro)'),
                onTap: () => Navigator.pop(c, ReminderTestKind.training),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (kind == null || !navigatorContext.mounted) {
    return;
  }
  try {
    await ReminderNotifications.showTest(kind);
    if (!navigatorContext.mounted) {
      return;
    }
    ScaffoldMessenger.of(navigatorContext).showSnackBar(
      const SnackBar(
        content: Text('Notificação de teste enviada.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    if (!navigatorContext.mounted) {
      return;
    }
    final missingPlugin =
        e is StateError && e.message == 'missing_native_plugin';
    final denied = e is StateError && e.message == 'permission_denied';
    ScaffoldMessenger.of(navigatorContext).showSnackBar(
      SnackBar(
        content: Text(
          missingPlugin
              ? 'Pare o app e inicie de novo com flutter run (hot reload não carrega o plugin de notificações).'
              : denied
              ? 'Ative as notificações para o Inove GLP nas definições do telemóvel.'
              : 'Não foi possível enviar a notificação neste dispositivo.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<void> _showRemindersSheet(BuildContext context, AppState s) async {
  var doseEnabled = s.doseReminderEnabled;
  var doseHour = s.doseReminderHour;
  var doseMinute = s.doseReminderMinute;
  var hydrationEnabled = s.hydrationReminderEnabled;
  var hydrationIntervalMin = s.hydrationReminderIntervalMin;
  var weightEnabled = s.weightReminderEnabled;
  var weightHour = s.weightReminderHour;
  var weightMinute = s.weightReminderMinute;
  var mealEnabled = s.mealReminderEnabled;
  var mealHour = s.mealReminderHour;
  var mealMinute = s.mealReminderMinute;
  var trainingEnabled = s.trainingReminderEnabled;
  var trainingHour = s.trainingReminderHour;
  var trainingMinute = s.trainingReminderMinute;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateSheet) {
          Future<void> pickTime({
            required int hour,
            required int minute,
            required void Function(TimeOfDay t) onSelected,
          }) async {
            final t = await showTimePicker(
              context: ctx,
              initialTime: TimeOfDay(hour: hour, minute: minute),
            );
            if (t == null) {
              return;
            }
            onSelected(t);
          }

          Future<void> save() async {
            await s.setReminderSettings(
              doseEnabled: doseEnabled,
              doseHour: doseHour,
              doseMinute: doseMinute,
              hydrationEnabled: hydrationEnabled,
              hydrationIntervalMin: hydrationIntervalMin,
              weightEnabled: weightEnabled,
              weightHour: weightHour,
              weightMinute: weightMinute,
              mealEnabled: mealEnabled,
              mealHour: mealHour,
              mealMinute: mealMinute,
              trainingEnabled: trainingEnabled,
              trainingHour: trainingHour,
              trainingMinute: trainingMinute,
            );
            if (!context.mounted) {
              return;
            }
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Preferências de lembretes salvas.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F2847), Color(0xFF0DB9A3)],
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lembretes PRO',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Automatize aplicação, hidratação, pesagem e refeições para manter consistência.',
                        style: TextStyle(
                          color: Colors.white,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _reminderBlock(
                  title: 'Aplicação',
                  subtitle: 'Lembrete principal da caneta',
                  icon: Icons.medication_liquid_rounded,
                  color: AppTheme.teal,
                  enabled: doseEnabled,
                  onEnabledChanged: (v) => setStateSheet(() => doseEnabled = v),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Horário da aplicação'),
                    subtitle: Text(_timeLabel(doseHour, doseMinute)),
                    trailing: TextButton(
                      onPressed: () => pickTime(
                        hour: doseHour,
                        minute: doseMinute,
                        onSelected: (t) {
                          setStateSheet(() {
                            doseHour = t.hour;
                            doseMinute = t.minute;
                          });
                        },
                      ),
                      child: const Text('Alterar'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _reminderBlock(
                  title: 'Hidratação',
                  subtitle: 'Intervalo recorrente ao longo do dia',
                  icon: Icons.water_drop_rounded,
                  color: AppTheme.hydrationTeal,
                  enabled: hydrationEnabled,
                  onEnabledChanged: (v) =>
                      setStateSheet(() => hydrationEnabled = v),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Frequência da água'),
                    subtitle: Slider(
                      value: hydrationIntervalMin.toDouble(),
                      min: 30,
                      max: 240,
                      divisions: 7,
                      label: '$hydrationIntervalMin min',
                      onChanged: (v) {
                        setStateSheet(() => hydrationIntervalMin = v.round());
                      },
                    ),
                    trailing: Text(
                      '$hydrationIntervalMin min',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _reminderBlock(
                  title: 'Pesagem',
                  subtitle: 'Check diário para evolução',
                  icon: Icons.monitor_weight_rounded,
                  color: AppTheme.navy,
                  enabled: weightEnabled,
                  onEnabledChanged: (v) =>
                      setStateSheet(() => weightEnabled = v),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Horário da pesagem'),
                    subtitle: Text(_timeLabel(weightHour, weightMinute)),
                    trailing: TextButton(
                      onPressed: () => pickTime(
                        hour: weightHour,
                        minute: weightMinute,
                        onSelected: (t) {
                          setStateSheet(() {
                            weightHour = t.hour;
                            weightMinute = t.minute;
                          });
                        },
                      ),
                      child: const Text('Alterar'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _reminderBlock(
                  title: 'Refeição proteica',
                  subtitle: 'Meta de proteína diária',
                  icon: Icons.restaurant_rounded,
                  color: AppTheme.purple,
                  enabled: mealEnabled,
                  onEnabledChanged: (v) => setStateSheet(() => mealEnabled = v),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Horário da refeição'),
                    subtitle: Text(_timeLabel(mealHour, mealMinute)),
                    trailing: TextButton(
                      onPressed: () => pickTime(
                        hour: mealHour,
                        minute: mealMinute,
                        onSelected: (t) {
                          setStateSheet(() {
                            mealHour = t.hour;
                            mealMinute = t.minute;
                          });
                        },
                      ),
                      child: const Text('Alterar'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _reminderBlock(
                  title: 'Treino',
                  subtitle: 'Notifica quando ficar 3 dias sem registrar treino',
                  icon: Icons.fitness_center_rounded,
                  color: AppTheme.navy,
                  enabled: trainingEnabled,
                  onEnabledChanged: (v) =>
                      setStateSheet(() => trainingEnabled = v),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Horário da checagem'),
                    subtitle: Text(_timeLabel(trainingHour, trainingMinute)),
                    trailing: TextButton(
                      onPressed: () => pickTime(
                        hour: trainingHour,
                        minute: trainingMinute,
                        onSelected: (t) {
                          setStateSheet(() {
                            trainingHour = t.hour;
                            trainingMinute = t.minute;
                          });
                        },
                      ),
                      child: const Text('Alterar'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickReminderToTest(ctx),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Testar lembretes'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppTheme.navy,
                    side: BorderSide(
                      color: AppTheme.navy.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: save,
                  child: const Text('Salvar lembretes'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

String _timeLabel(int hour, int minute) {
  final h = hour.toString().padLeft(2, '0');
  final m = minute.toString().padLeft(2, '0');
  return '$h:$m';
}

Widget _reminderBlock({
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required bool enabled,
  required ValueChanged<bool> onEnabledChanged,
  required Widget child,
}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: color.withValues(alpha: 0.08),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onEnabledChanged),
          ],
        ),
        if (enabled) child,
      ],
    ),
  );
}

void _showProfileEditSheet(
  BuildContext context,
  AppState s,
  UserProfile current,
) {
  final formKey = GlobalKey<FormState>();
  final nameC = TextEditingController(text: current.name);
  final emailC = TextEditingController(text: current.email ?? '');
  final ageC = TextEditingController(text: current.age.toString());
  final heightC = TextEditingController(text: current.heightCm.toString());
  final startWeightC = TextEditingController(
    text: current.startWeightKg.toStringAsFixed(1),
  );
  final goalWeightC = TextEditingController(
    text: current.goalWeightKg.toStringAsFixed(1),
  );
  final frequencyC = TextEditingController(
    text: current.frequencyDays.toString(),
  );
  var sex = current.sex;
  var activityKey = current.activityKey;
  var saving = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateSheet) {
          Future<void> onSave() async {
            final ok = formKey.currentState?.validate() ?? false;
            if (!ok || saving) {
              return;
            }
            setStateSheet(() => saving = true);
            final next = UserProfile(
              usingGlp1: current.usingGlp1,
              medicationLine: current.medicationLine,
              doseLabel: current.doseLabel,
              frequencyDays: int.parse(frequencyC.text.trim()),
              sex: sex,
              age: int.parse(ageC.text.trim()),
              heightCm: int.parse(heightC.text.trim()),
              startWeightKg: double.parse(
                startWeightC.text.trim().replaceAll(',', '.'),
              ),
              goalWeightKg: double.parse(
                goalWeightC.text.trim().replaceAll(',', '.'),
              ),
              activityKey: activityKey,
              name: nameC.text.trim(),
              email: emailC.text.trim().isEmpty ? null : emailC.text.trim(),
              password: current.password,
              proteinTargetG: current.proteinTargetG,
              fiberTargetG: current.fiberTargetG,
              waterTargetL: current.waterTargetL,
              carbTargetG: current.carbTargetG,
            );
            await s.updateProfile(next, recomputeTargets: true);
            if (!context.mounted) {
              return;
            }
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Perfil atualizado com sucesso.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Form(
              key: formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Editar perfil',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameC,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o nome'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailC,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: sex,
                    decoration: const InputDecoration(labelText: 'Sexo'),
                    items: const [
                      DropdownMenuItem(value: 'f', child: Text('Feminino')),
                      DropdownMenuItem(value: 'm', child: Text('Masculino')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setStateSheet(() => sex = v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: activityKey,
                    decoration: const InputDecoration(
                      labelText: 'Atividade física',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'sedentary',
                        child: Text('Sedentário'),
                      ),
                      DropdownMenuItem(
                        value: 'light',
                        child: Text('Levemente ativo'),
                      ),
                      DropdownMenuItem(
                        value: 'moderate',
                        child: Text('Moderado'),
                      ),
                      DropdownMenuItem(
                        value: 'intense',
                        child: Text('Intenso'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setStateSheet(() => activityKey = v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: ageC,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Idade'),
                          validator: (v) {
                            final n = int.tryParse(v?.trim() ?? '');
                            if (n == null || n < 15 || n > 90) return '15-90';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: heightC,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Altura (cm)',
                          ),
                          validator: (v) {
                            final n = int.tryParse(v?.trim() ?? '');
                            if (n == null || n < 120 || n > 220)
                              return '120-220';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: startWeightC,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Peso inicial (kg)',
                          ),
                          validator: (v) {
                            final n = double.tryParse(
                              (v ?? '').trim().replaceAll(',', '.'),
                            );
                            if (n == null || n < 40 || n > 350) return '40-350';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: goalWeightC,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Meta (kg)',
                          ),
                          validator: (v) {
                            final n = double.tryParse(
                              (v ?? '').trim().replaceAll(',', '.'),
                            );
                            if (n == null || n < 35 || n > 320) return '35-320';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: frequencyC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Frequência da aplicação (dias)',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n < 1 || n > 30) return '1-30';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: saving ? null : onSave,
                    child: Text(saving ? 'Salvando...' : 'Salvar alterações'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _pickProfilePhoto(BuildContext context, AppState s) async {
  final src = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (c) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
          ],
        ),
      );
    },
  );
  if (src == null || !context.mounted) return;
  if (!kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS) &&
      src == ImageSource.camera) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No desktop, use a galeria para foto de perfil.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  try {
    final x = await ImagePicker().pickImage(
      source: src,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (x == null) return;
    await s.setProfilePhotoPath(x.path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto do perfil atualizada.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } on MissingPluginException {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plugin de imagem não carregou. Reinicie o app com flutter run.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível abrir câmera/galeria.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
