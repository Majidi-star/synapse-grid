import 'dart:math';
import 'package:flutter/material.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'rating_buttons.dart';

class FlashcardWidget extends StatefulWidget {
  final String frontText;
  final String backText;
  final bool isFlipped;
  final VoidCallback onFlip;
  final Function(int) onRate;

  const FlashcardWidget({
    Key? key,
    required this.frontText,
    required this.backText,
    required this.isFlipped,
    required this.onFlip,
    required this.onRate,
  }) : super(key: key);

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.2, 0.8, 0.2, 1),
    );

    if (widget.isFlipped) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FlashcardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.isFlipped) {
          widget.onFlip();
        }
      },
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final value = _animation.value;
            final isFrontVisible = value < 0.5;

            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(value * pi);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: isFrontVisible
                  ? _buildFrontSide(context)
                  : Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: _buildBackSide(context),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrontSide(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.onSurface.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Spacer(),
          Text(
            widget.frontText,
            textAlign: TextAlign.center,
            style: textTheme.displayLarge?.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            'TAP TO REVEAL',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.primaryContainer.withOpacity(0.7),
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryContainer.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Spacer(),
          Text(
            widget.backText,
            textAlign: TextAlign.center,
            style: textTheme.displayLarge?.copyWith(
              color: AppColors.primaryContainer,
            ),
          ),
          const Spacer(),
          RatingButtons(onRate: widget.onRate),
        ],
      ),
    );
  }
}
