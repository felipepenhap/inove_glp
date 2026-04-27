import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/subscription_tier.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';

void showProPlanSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Consumer<AppState>(
            builder: (context, s, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Inove GLP — PRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Relatório PDF, mapa de aplicação sugerida (PRO), histórico alimentar ampliado, relatórios com IA e lembretes avançados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      await s.setSubscription(
                        s.isPro ? SubscriptionTier.free : SubscriptionTier.pro,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(ctx).pop();
                      final after = context.read<AppState>();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            after.isPro
                                ? 'Plano PRO ativado (demo).'
                                : 'Plano grátis (demo).',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      s.isPro ? 'Desativar PRO (demo)' : 'Ativar PRO (demo)',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
