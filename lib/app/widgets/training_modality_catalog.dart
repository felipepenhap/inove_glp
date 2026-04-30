import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

typedef TrainingModalityDef = ({
  String key,
  String label,
  IconData icon,
  Color accent,
});

const List<TrainingModalityDef> kTrainingModalities = [
  (
    key: 'strength',
    label: 'Musculação',
    icon: Icons.fitness_center_rounded,
    accent: Color(0xFF7C3AED),
  ),
  (
    key: 'running',
    label: 'Corrida',
    icon: Icons.directions_run_rounded,
    accent: Color(0xFFE11D48),
  ),
  (
    key: 'walking',
    label: 'Caminhada',
    icon: Icons.directions_walk_rounded,
    accent: Color(0xFF0D9488),
  ),
  (
    key: 'swimming',
    label: 'Natação',
    icon: Icons.pool_rounded,
    accent: Color(0xFF2563EB),
  ),
  (
    key: 'cycling',
    label: 'Bicicleta',
    icon: Icons.pedal_bike_rounded,
    accent: Color(0xFFEA580C),
  ),
  (
    key: 'mixed',
    label: 'Misto',
    icon: Icons.sports_rounded,
    accent: AppTheme.teal,
  ),
];
