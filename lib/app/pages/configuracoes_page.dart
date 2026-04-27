import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_profile.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/modern_card.dart';
import '../widgets/section_header.dart';
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

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        const SizedBox(height: 4),
        ModernCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const AppLogo(size: 56, borderRadius: 16),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inove GLP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Controle do seu tratamento',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(
          title: 'Conta e conteúdo',
          subtitle: 'Perfil, relatórios e planos',
        ),
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
                  child: const Icon(Icons.person_rounded, color: AppTheme.teal, size: 24),
                ),
                title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  p == null
                      ? '—'
                      : _profileSubtitle(p),
                ),
                isThreeLine: p != null && (p.email != null && p.email!.isNotEmpty),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        ModernCard(
          onTap: () {
            final s = context.read<AppState>();
            if (s.isPro) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Relatórios com IA: em breve.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              showProPlanSheet(context);
            }
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
              child: const Icon(Icons.auto_awesome, color: AppTheme.purple, size: 24),
            ),
            title: const Text('Relatórios com IA', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('Resumos e insights a partir dos seus dados'),
            trailing: Consumer<AppState>(
              builder: (context, s, _) {
                if (!s.isPro) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.teal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }
                return const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted);
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        ModernCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Relatórios'),
                    leading: const BackButton(),
                  ),
                  body: const RelatoriosPage(),
                ),
              ),
            );
          },
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _RoundIcon(
              child: Icon(Icons.picture_as_pdf_outlined, color: AppTheme.navy, size: 24),
            ),
            title: Text('Relatórios e exportação', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('PDF e resumos para o seu médico'),
            trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ),
        ),
        const SizedBox(height: 8),
        Consumer<AppState>(
          builder: (context, s, _) {
            return ModernCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _RoundIcon(
                  child: Icon(Icons.workspace_premium_rounded, color: AppTheme.teal, size: 24),
                ),
                title: const Text('Planos', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(s.isPro ? 'PRO ativo' : 'Gratuito — desbloqueie mais recursos'),
                trailing: FilledButton.tonal(
                  onPressed: () => showProPlanSheet(context),
                  child: Text(s.isPro ? 'Gerir' : 'Ver planos'),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
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
              child: Icon(Icons.menu_book_rounded, color: AppTheme.teal, size: 24),
            ),
            title: Text('Dicas e indicações', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('Hidratação, dose, peso e mais'),
            trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ),
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
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Row(
              children: [
                AppLogo(size: 44, borderRadius: 12),
                SizedBox(width: 12),
                Text('Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Nome'),
              subtitle: Text(p.name.isNotEmpty ? p.name : '—'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Email'),
              subtitle: Text(
                p.email != null && p.email!.isNotEmpty ? p.email! : '—',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Peso inicial / meta'),
              subtitle: Text('${p.startWeightKg.toStringAsFixed(1)} kg → ${p.goalWeightKg.toStringAsFixed(1)} kg'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dose (referência)'),
              subtitle: Text(p.doseLabel.isNotEmpty ? p.doseLabel : '—'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Periodicidade'),
              subtitle: Text('A cada ${p.frequencyDays} dia(s)'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edição completa: integrar no fluxo de onboarding.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Ok'),
            ),
          ],
        ),
      );
    },
  );
}
