import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';

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
          'Statistics',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStreakHighlight(context),
            const SizedBox(height: 48),
            _buildMasteryLevels(context),
            const SizedBox(height: 48),
            _buildStudyConsistency(context),
            const SizedBox(height: 48),
            _buildStatsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakHighlight(BuildContext context) {
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
            Icons.local_fire_department,
            color: AppColors.primaryContainer,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '14 Day Streak',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Keep it up!',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMasteryLevels(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MASTERY LEVELS',
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.onSurface.withOpacity(0.5),
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: [
              Expanded(
                flex: 20, // 20%
                child: Container(color: AppColors.tertiaryContainer),
              ),
              Expanded(
                flex: 50, // 50%
                child: Container(color: AppColors.primaryContainer),
              ),
              Expanded(
                flex: 30, // 30%
                child: Container(color: AppColors.onSurface.withOpacity(0.2)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendItem(context, AppColors.tertiaryContainer, 'Learning', '20%'),
            _buildLegendItem(context, AppColors.primaryContainer, 'Review', '50%'),
            _buildLegendItem(context, AppColors.onSurface.withOpacity(0.2), 'Mastered', '30%'),
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
          ),
        ),
        const SizedBox(width: 4),
        Text(
          percentage,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStudyConsistency(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final opacities = [0.3, 0.6, 0.2, 0.8, 0.5, 0.9, 1.0]; // Mock activity levels

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STUDY CONSISTENCY (7 DAYS)',
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.onSurface.withOpacity(0.5),
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            final isToday = index == 6; // Sunday is today in this mock
            return Column(
              children: [
                Container(
                  width: 24,
                  height: 100 * opacities[index],
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer.withOpacity(isToday ? 1.0 : opacities[index]),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: AppColors.tertiaryContainer.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  days[index],
                  style: textTheme.labelSmall?.copyWith(
                    color: isToday ? AppColors.primaryContainer : AppColors.onSurface.withOpacity(0.5),
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.speed,
            label: 'Avg Speed',
            value: '4.2s /card',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.psychology,
            label: 'Retention',
            value: '92%',
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
        borderRadius: BorderRadius.circular(12),
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
            ),
          ),
        ],
      ),
    );
  }
}
