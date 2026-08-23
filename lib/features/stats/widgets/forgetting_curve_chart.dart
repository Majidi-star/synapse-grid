import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ForgettingCurveChart extends StatelessWidget {
  final List<({double days, double retention})> curveData;
  final double averageStability;

  const ForgettingCurveChart({
    super.key,
    required this.curveData,
    this.averageStability = 3.12,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGold = Color(0xFFE3C36C);
    const surfaceContainer = Color(0xFF21201B);
    const onSurface = Color(0xFFE7E2DA);
    const onSurfaceVariant = Color(0xFFCFC5B3);

    // Generate theoretical curve points: R = (1 + t / (9 * S))^-1
    final List<FlSpot> theoreticalSpots = [];
    final double s = averageStability <= 0 ? 3.12 : averageStability;
    for (double t = 0; t <= 30; t += 0.5) {
      final double r = 1.0 / (1.0 + t / (9.0 * s));
      theoreticalSpots.add(FlSpot(t, r * 100));
    }

    // Map actual user coordinates
    final List<FlSpot> actualSpots = curveData
        .where((pt) => pt.days <= 30)
        .map((pt) => FlSpot(pt.days, pt.retention))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RETENTION CURVE (FSRS VS. ACTUAL)',
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
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 16, 24, 8),
          decoration: BoxDecoration(
            color: surfaceContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: onSurface.withOpacity(0.05)),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: onSurface.withOpacity(0.03),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${value.toInt()}d',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 10,
                            color: onSurface.withOpacity(0.4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 10,
                          color: onSurface.withOpacity(0.4),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 30,
              minY: 0,
              maxY: 100,
              lineBarsData: [
                // Theoretical curve (solid thin gold line)
                LineChartBarData(
                  spots: theoreticalSpots,
                  isCurved: true,
                  color: primaryGold.withOpacity(0.5),
                  barWidth: 1.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: primaryGold.withOpacity(0.02),
                  ),
                ),
                // Actual user points (scatter dots)
                if (actualSpots.isNotEmpty)
                  LineChartBarData(
                    spots: actualSpots,
                    show: true,
                    color: const Color(0xFFB9C3FF), // tertiary accent
                    barWidth: 0, // hide joining line, show only dots
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFFB9C3FF),
                        strokeWidth: 1,
                        strokeColor: surfaceContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
