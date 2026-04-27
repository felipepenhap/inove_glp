import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/weight_entry.dart';
import '../../core/theme/app_theme.dart';

class WeightLossChart extends StatelessWidget {
  const WeightLossChart({
    super.key,
    required this.entries,
  });

  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Registre o peso para ver a curva',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }
    final sorted = [...entries]..sort((a, b) => a.at.compareTo(b.at));
    if (sorted.length == 1) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Peso: ${sorted.first.kg.toStringAsFixed(1)} kg. Registre de novo em outro dia para acompanhar a queda.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }
    var minK = sorted.map((e) => e.kg).reduce((a, b) => a < b ? a : b);
    var maxK = sorted.map((e) => e.kg).reduce((a, b) => a > b ? a : b);
    final pad = ((maxK - minK) * 0.15).clamp(0.3, 3.0);
    final yMin = minK - pad;
    final yMax = maxK + pad;
    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++) FlSpot(i.toDouble(), sorted[i].kg),
    ];
    final n = sorted.length;
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
            horizontalInterval: (yMax - yMin) > 4 ? 2 : 1,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: n > 5 ? 2 : 1,
                getTitlesWidget: (v, m) {
                  final i = v.round();
                  if (i < 0 || i >= n) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('d/M', 'pt_BR').format(sorted[i].at),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, m) {
                  return Text(
                    v.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (n - 1).toDouble().clamp(1, 1000),
          minY: yMin,
          maxY: yMax,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.teal,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.teal.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
