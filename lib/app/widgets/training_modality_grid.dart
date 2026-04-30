import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'training_modality_catalog.dart';

class TrainingModalityGrid extends StatelessWidget {
  const TrainingModalityGrid({
    super.key,
    required this.selectedKeys,
    required this.onChanged,
  });

  final List<String> selectedKeys;
  final ValueChanged<List<String>> onChanged;

  void _toggle(String key) {
    final next = List<String>.from(selectedKeys);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    if (next.isEmpty) {
      next.add('strength');
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cross = w >= 400 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cross,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: kTrainingModalities.map((m) {
            final on = selectedKeys.contains(m.key);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _toggle(m.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: on
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              m.accent.withValues(alpha: 0.85),
                              AppTheme.navy.withValues(alpha: 0.88),
                            ],
                          )
                        : null,
                    color: on ? null : AppTheme.surfaceCard,
                    border: Border.all(
                      color: on
                          ? Colors.white.withValues(alpha: 0.35)
                          : AppTheme.navy.withValues(alpha: 0.08),
                      width: on ? 1.4 : 1,
                    ),
                    boxShadow: on
                        ? [
                            BoxShadow(
                              color: m.accent.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : AppTheme.softCardShadow,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        m.icon,
                        size: 28,
                        color: on ? Colors.white : m.accent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          height: 1.15,
                          color: on ? Colors.white : AppTheme.navy,
                        ),
                      ),
                      if (on) ...[
                        const SizedBox(height: 4),
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
