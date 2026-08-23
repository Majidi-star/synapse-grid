import 'package:flutter/material.dart';
import 'package:recall_app/core/theme/app_colors.dart';

class RatingButtons extends StatefulWidget {
  final Function(int rating) onRate;
  final bool enabled;

  const RatingButtons({
    Key? key,
    required this.onRate,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<RatingButtons> createState() => _RatingButtonsState();
}

class _RatingButtonsState extends State<RatingButtons> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildButton(
          label: 'AGAIN',
          rating: 1,
          interval: '<1m',
          bgColor: Colors.transparent,
          borderColor: AppColors.onSurface.withValues(alpha: 0.1),
          textColor: AppColors.error,
        ),
        const SizedBox(width: 8),
        _buildButton(
          label: 'HARD',
          rating: 2,
          interval: '5m',
          bgColor: Colors.transparent,
          borderColor: AppColors.onSurface.withValues(alpha: 0.1),
          textColor: AppColors.onSurface.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 8),
        _buildButton(
          label: 'GOOD',
          rating: 3,
          interval: '1d',
          bgColor: Colors.transparent,
          borderColor: AppColors.onSurface.withValues(alpha: 0.2),
          textColor: AppColors.onSurface,
        ),
        const SizedBox(width: 8),
        _buildButton(
          label: 'EASY',
          rating: 4,
          interval: '4d',
          bgColor: AppColors.primaryContainer.withValues(alpha: 0.1),
          borderColor: AppColors.primaryContainer.withValues(alpha: 0.4),
          textColor: AppColors.primaryContainer,
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required int rating,
    required String interval,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Expanded(
      child: _RatingButton(
        label: label,
        interval: interval,
        bgColor: bgColor,
        borderColor: borderColor,
        textColor: textColor,
        enabled: widget.enabled,
        onTap: () {
          if (widget.enabled) {
            widget.onRate(rating);
          }
        },
      ),
    );
  }
}

class _RatingButton extends StatefulWidget {
  final String label;
  final String interval;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final bool enabled;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.interval,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_RatingButton> createState() => _RatingButtonState();
}

class _RatingButtonState extends State<_RatingButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTapDown: (_) {
        if (widget.enabled) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.enabled) {
          setState(() => _isPressed = false);
          widget.onTap();
        }
      },
      onTapCancel: () {
        if (widget.enabled) setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  border: Border.all(color: widget.borderColor, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: textTheme.labelMedium?.copyWith(
                    color: widget.textColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.interval,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
