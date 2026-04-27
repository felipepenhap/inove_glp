import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/modern_card.dart';

class IndicacoesPage extends StatelessWidget {
  const IndicacoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = <Map<String, String>>[
      {
        't': 'Hidratação e GLP-1',
        's': 'Mantenha água ao longo do dia e observe náusea ou desconforto; avise o médico se persistir.',
      },
      {
        't': 'Evolução da dose',
        's': 'Ajuste de dose deve seguir prescrição. Use o app para lembrar a periodicidade, não o valor.',
      },
      {
        't': 'Peso e massa magra',
        's': 'Priorize proteína (como combinado com seu time de saúde) e força, quando liberado.',
      },
      {
        't': 'Hipo e uso de caneta',
        's': 'Sintomas de glicose baixa podem ocorrer (contexto pessoal). Siga o plano do seu endocrinologista.',
      },
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        return ModernCard(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: ListTile(
            leading: const Icon(Icons.medical_services_rounded, color: AppTheme.teal, size: 28),
            title: Text(
              items[i]['t'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navy),
            ),
            subtitle: Text(
              items[i]['s'] ?? '',
              style: const TextStyle(height: 1.45, color: AppTheme.textMuted, fontSize: 13),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
