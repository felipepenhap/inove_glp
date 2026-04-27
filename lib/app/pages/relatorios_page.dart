import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/subscription_tier.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/modern_card.dart';
import 'pro_plan_sheet.dart';

class RelatoriosPage extends StatelessWidget {
  const RelatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Relatórios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.navy)),
        const SizedBox(height: 8),
        const Text(
          'Grátis: resumo básico. PRO: exportação PDF, mais histórico e blocos com cor.',
          style: TextStyle(color: AppTheme.textMuted, height: 1.4),
        ),
        const SizedBox(height: 16),
        Consumer<AppState>(
          builder: (context, s, _) {
            return ModernCard(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppTheme.navy),
                title: const Text('Exportar PDF'),
                subtitle: const Text('Para médico / nutri — exclusivo PRO'),
                trailing: s.isPro
                    ? FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Geração de PDF: conectar a backend ou printing local.'),
                            ),
                          );
                        },
                        child: const Text('Gerar'),
                      )
                    : const Text('PRO'),
                onTap: s.isPro
                    ? null
                    : () {
                        showProPlanSheet(context);
                      },
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ModernCard(
          child: const ListTile(
            leading: Icon(Icons.menu_book_rounded, color: AppTheme.navy, size: 28),
            title: Text('Fontes médicas usadas no app', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('Diretrizes e literatura: integração futura (links)'),
          ),
        ),
        const SizedBox(height: 12),
        Consumer<AppState>(
          builder: (context, s, _) {
            return ListTile(
              title: Text(
                s.isPro ? 'Você está no PRO' : 'Plano grátis',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: FilledButton.tonal(
                onPressed: () {
                  showProPlanSheet(context);
                },
                child: Text(
                  s.isPro ? 'Gerir' : 'Ver PRO',
                ),
              ),
            );
          },
        ),
        Consumer<AppState>(
          builder: (context, s, _) {
            if (!s.isPro) {
              return const SizedBox.shrink();
            }
            return FilledButton(
              onPressed: () {
                s.setSubscription(SubscriptionTier.free);
              },
              child: const Text('Voltar para grátis (demo)'),
            );
          },
        ),
      ],
    );
  }
}
