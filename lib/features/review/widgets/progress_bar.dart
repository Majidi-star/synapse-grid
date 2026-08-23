import 'package:flutter/material.dart';
import 'package:recall_app/core/theme/app_colors.dart';

class SessionProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final String deckName;

  const SessionProgressBar({
    Key? key,
    required this.current,
    required this.total,
    required this.deckName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                deckName.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.5),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$current / $total',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.5),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            width: double.infinity,
            color: AppColors.onSurface.withOpacity(0.1),
            alignment: Alignment.centerLeft,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  height: 1,
                  width: constraints.maxWidth * progress,
                  color: AppColors.primaryContainer,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
