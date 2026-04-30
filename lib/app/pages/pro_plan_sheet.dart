import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/subscription_tier.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';

void showProPlanSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final message = Uri.encodeComponent(
        'Olá! Quero solicitar a ativação do plano PRO do Inove GLP por R\$ 19,90/mês.',
      );
      final whatsappUri = Uri.parse(
        'https://wa.me/5519996824322?text=$message',
      );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F2847),
                      Color(0xFF1A4C6A),
                      Color(0xFF0DB9A3),
                    ],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inove GLP PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Acompanhamento premium para maximizar consistência e resultados.',
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'R\$ 19,90',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/mês',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.navy.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Benefícios inclusos no PRO',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _benefit('Relatórios com IA mais completos por período'),
              _benefit('Exportação de relatório em PDF para médico e nutrição'),
              _benefit('Insights avançados de evolução e aderência'),
              _benefit(
                'Central de lembretes inteligentes (aplicação, água, pesagem e proteína)',
              ),
              _benefit('Histórico estendido e recomendações personalizadas'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final ok = await launchUrl(
                    whatsappUri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!context.mounted) {
                    return;
                  }
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Não foi possível abrir o WhatsApp neste dispositivo.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('Solicitar ativação no WhatsApp'),
              ),
              const SizedBox(height: 10),
              Consumer<AppState>(
                builder: (context, s, _) {
                  return OutlinedButton(
                    onPressed: () async {
                      final wasPro = s.isPro;
                      await s.setSubscription(
                        s.isPro ? SubscriptionTier.free : SubscriptionTier.pro,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      if (!wasPro && s.isPro) {
                        await _showProActivatedDialog(context);
                        if (!context.mounted) {
                          return;
                        }
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            s.isPro
                                ? 'Plano PRO ativado para teste.'
                                : 'Plano gratuito ativado.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text(
                      s.isPro
                          ? 'Desativar PRO (teste)'
                          : 'Ativar plano PRO (teste)',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showProActivatedDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'pro_activated',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    pageBuilder: (ctx, anim1, anim2) => const _ProActivatedOverlay(),
    transitionBuilder: (context, anim, secAnim, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(curve), child: child),
      );
    },
  );
}

class _ProActivatedOverlay extends StatefulWidget {
  const _ProActivatedOverlay();

  @override
  State<_ProActivatedOverlay> createState() => _ProActivatedOverlayState();
}

class _ProActivatedOverlayState extends State<_ProActivatedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F2847), Color(0xFF1A4C6A), Color(0xFF0DB9A3)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.navy.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                  CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
                ),
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFDE047),
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Plano PRO ativado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Recursos premium liberados.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.navy,
                ),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _benefit(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle, color: AppTheme.teal, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.navy,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
