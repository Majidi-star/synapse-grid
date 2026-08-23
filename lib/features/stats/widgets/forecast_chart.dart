import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ForecastChart extends StatelessWidget {
  final List<({DateTime date, int count})> forecastData;

  const ForecastChart({
    super.key,
    required this.forecastData,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGold = Color(0xFFE3C36C);
    const surfaceContainer = Color(0xFF21201B);
    const onSurface = Color(0xFFE7E2DA);
    const onSurfaceVariant = Color(0xFFCFC5B3);

    // Build the spots for the next 30 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Map<int, int> countsByOffset = {};
    for (final entry in forecastData) {
      final diff = entry.date.difference(today).inDays;
      if (diff >= 0 && diff < 30) {
        countsByOffset[diff] = entry.count;
      }
    }

    final List<BarChartGroupData> barGroups = [];
    int maxCount = 5; // minimum scale

    for (int i = 0; i < 30; i++) {
      final count = countsByOffset[i] ?? 0;
      if (count > maxCount) {
        maxCount = count;
      }

      final isToday = i == 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: isToday ? primaryGold : const Color(0xFFB9C3FF).withOpacity(0.6),
              width: 6,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxCount.toDouble(),
                color: onSurface.withOpacity(0.02),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '30-DAY REVIEW FORECAST',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: onSurface.withOpacity(0.05)),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxCount.toDouble(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => surfaceContainer,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dayLabel = groupIndex == 0 ? 'Today' : 'Day +$groupIndex';
                    return BarTooltipItem(
                      '$dayLabel\n${rod.toY.toInt()} cards due',
                      const TextStyle(
                        fontFamily: 'Geist',
                        color: primaryGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: (maxCount / 4).clamp(1.0, 100.0).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 10,
                          color: onSurface.withOpacity(0.4),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final val = value.toInt();
                      if (val == 0 || val == 10 || val == 20 || val == 29) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            val == 0 ? 'Today' : '+$val d',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 9,
                              color: onSurface.withOpacity(0.4),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }
}
