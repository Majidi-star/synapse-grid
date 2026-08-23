import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/models/scheduler_state.dart';
import 'package:recall_app/providers/stats_providers.dart';
import 'package:recall_app/providers/advanced_stats_providers.dart';
import 'widgets/heatmap_widget.dart';
import 'widgets/forgetting_curve_chart.dart';
import 'widgets/forecast_chart.dart';

class StatsScreen extends ConsumerWidget {
  final String deckId;
  final String deckName;

  const StatsScreen({
    Key? key,
    required this.deckId,
    required this.deckName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    // Load basic stats
    final streakAsync = ref.watch(streakProvider);
    final masteryAsync = ref.watch(masteryBreakdownProvider(deckId));
    final speedAsync = ref.watch(averageSpeedProvider(deckId));
    final retentionAsync = ref.watch(retentionRateProvider(deckId));

    // Load advanced stats
    final curveAsync = ref.watch(retentionCurveProvider(deckId));
    final forecastAsync = ref.watch(reviewForecastProvider(deckId));
    final heatmapAsync = ref.watch(heatmapDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '$deckName Stats',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak Highlight Card
            streakAsync.when(
              data: (streak) => _buildStreakHighlight(context, streak),
              loading: () => const SizedBox(height: 56),
              error: (_, __) => _buildStreakHighlight(context, 0),
            ),
            const SizedBox(height: 32),

            // Mastery Levels Segmented Line
            masteryAsync.when(
              data: (mastery) => _buildMasteryLevels(context, mastery),
              loading: () => const SizedBox(height: 70),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),

            // Averages and stats grid
            Row(
              children: [
                Expanded(
                  child: speedAsync.when(
                    data: (speed) => _buildStatCard(
                      context,
                      icon: Icons.speed_rounded,
                      label: 'Avg Speed',
                      value: '${(speed / 1000).toStringAsFixed(1)}s /card',
                    ),
                    loading: () => const SizedBox(height: 80),
                    error: (_, __) => _buildStatCard(context, icon: Icons.speed, label: 'Avg Speed', value: '--'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: retentionAsync.when(
                    data: (rate) => _buildStatCard(
                      context,
                      icon: Icons.psychology_rounded,
                      label: 'Retention',
                      value: '${(rate * 100).toStringAsFixed(0)}%',
                    ),
                    loading: () => const SizedBox(height: 80),
                    error: (_, __) => _buildStatCard(context, icon: Icons.psychology, label: 'Retention', value: '--'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Heatmap consistency widget
            heatmapAsync.when(
              data: (heatmap) => HeatmapWidget(data: heatmap),
              loading: () => const SizedBox(height: 180),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),

            // Review Forecast Bar Chart
            forecastAsync.when(
              data: (forecast) => ForecastChart(forecastData: forecast),
              loading: () => const SizedBox(height: 200),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),

            // Retention Curve line chart
            curveAsync.when(
              data: (curve) => ForgettingCurveChart(curveData: curve),
              loading: () => const SizedBox(height: 220),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakHighlight(BuildContext context, int streak) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryContainer.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.primaryContainer,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$streak Day Streak',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              streak > 0 ? 'Keep the fire burning!' : 'Study today to start a streak!',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.onSurface.withOpacity(0.6),
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMasteryLevels(BuildContext context, Map<CardState, int> breakdown) {
    final textTheme = Theme.of(context).textTheme;

    final learning = breakdown[CardState.learning] ?? 0;
    final review = breakdown[CardState.review] ?? 0;
    final relearning = breakdown[CardState.relearning] ?? 0;
    final newCard = breakdown[CardState.newCard] ?? 0;

    final totalActive = learning + review + relearning + newCard;
    if (totalActive == 0) return const SizedBox.shrink();

    final double learningPct = (learning + relearning) / totalActive;
    final double reviewPct = review / totalActive;
    final double newPct = newCard / totalActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DECK MASTERY LEVELS',
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.onSurface.withOpacity(0.5),
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: [
              if (learningPct > 0)
                Expanded(
                  flex: (learningPct * 100).round(),
                  child: Container(color: const Color(0xFFB9C3FF)), // Periwinkle
                ),
              if (reviewPct > 0)
                Expanded(
                  flex: (reviewPct * 100).round(),
                  child: Container(color: const Color(0xFFE3C36C)), // Gold
                ),
              if (newPct > 0)
                Expanded(
                  flex: (newPct * 100).round(),
                  child: Container(color: AppColors.onSurface.withOpacity(0.15)), // Grey
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendItem(
              context,
              const Color(0xFFB9C3FF),
              'Learning',
              '${(learningPct * 100).toStringAsFixed(0)}%',
            ),
            _buildLegendItem(
              context,
              const Color(0xFFE3C36C),
              'Review',
              '${(reviewPct * 100).toStringAsFixed(0)}%',
            ),
            _buildLegendItem(
              context,
              AppColors.onSurface.withOpacity(0.15),
              'New',
              '${(newPct * 100).toStringAsFixed(0)}%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label, String percentage) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.onSurface.withOpacity(0.7),
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(width: 4),
        Text(
          percentage,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {required IconData icon, required String label, required String value}) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurface.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.onSurface.withOpacity(0.6)),
              const SizedBox(width: 8),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.6),
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }
}
