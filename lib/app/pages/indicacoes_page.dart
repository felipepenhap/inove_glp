import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/modern_card.dart';

class IndicacoesPage extends StatelessWidget {
  const IndicacoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = <_TipItem>[
      _TipItem(
        title: 'Hidratação estratégica',
        description:
            'Distribua água ao longo do dia em pequenas metas. Priorize hidratação antes das refeições para reduzir desconfortos gastrointestinais.',
        icon: Icons.water_drop_rounded,
        color: AppTheme.hydrationTeal,
      ),
      _TipItem(
        title: 'Evolução da dose com segurança',
        description:
            'Mudanças de dose devem seguir prescrição. Use os lembretes do app para manter regularidade sem autoajuste de medicação.',
        icon: Icons.safety_check_rounded,
        color: AppTheme.purple,
      ),
      _TipItem(
        title: 'Proteína e massa magra',
        description:
            'Inclua proteína em todas as refeições principais. Isso ajuda saciedade e preservação de massa magra durante a perda de peso.',
        icon: Icons.fitness_center_rounded,
        color: AppTheme.navy,
      ),
      _TipItem(
        title: 'Fibras e controle de apetite',
        description:
            'Fibras em vegetais, leguminosas e frutas com casca ajudam intestino, saciedade e controle glicêmico diário.',
        icon: Icons.eco_rounded,
        color: AppTheme.success,
      ),
      _TipItem(
        title: 'Atividade física progressiva',
        description:
            'Comece com metas sustentáveis: caminhada, mobilidade e exercícios de força conforme liberação clínica.',
        icon: Icons.directions_walk_rounded,
        color: AppTheme.teal,
      ),
      _TipItem(
        title: 'Sono e recuperação',
        description:
            'Durma entre 7 e 9 horas para melhorar adesão alimentar, energia e resposta metabólica ao tratamento.',
        icon: Icons.dark_mode_rounded,
        color: AppTheme.purpleDeep,
      ),
      _TipItem(
        title: 'Sinais de alerta',
        description:
            'Persistindo náusea intensa, vômito, dor abdominal forte ou hipoglicemia, procure orientação médica rapidamente.',
        icon: Icons.health_and_safety_rounded,
        color: Colors.deepOrange,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
                'Dicas e indicações',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Conteúdo prático para melhorar adesão, conforto e resultados no uso de GLP-1.',
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
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ModernCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.navy,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(
                            height: 1.45,
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TipItem {
  const _TipItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}
