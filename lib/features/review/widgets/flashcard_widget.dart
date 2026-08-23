import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/models/card.dart';
import 'rating_buttons.dart';
import 'cloze_card_widget.dart';
import 'image_occlusion_widget.dart';

class FlashcardWidget extends StatefulWidget {
  final FlashCard card;
  final bool isFlipped;
  final VoidCallback onFlip;
  final Function(int) onRate;

  const FlashcardWidget({
    Key? key,
    required this.card,
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
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
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
        _playAudio();
      } else {
        _controller.reverse();
      }
    }
    if (widget.card.id != oldWidget.card.id) {
      // Play audio on new card load
      _playAudio();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  String? _getAudioPath() {
    if (widget.card.extraData == null) return null;
    try {
      final data = jsonDecode(widget.card.extraData!);
      return data['audioPath'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _playAudio() async {
    final path = _getAudioPath();
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        try {
          await _audioPlayer?.stop();
          await _audioPlayer?.play(DeviceFileSource(path));
        } catch (e) {
          debugPrint('Playback error: $e');
        }
      }
    }
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
    final hasAudio = _getAudioPath() != null;

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
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hasAudio)
                IconButton(
                  onPressed: _playAudio,
                  icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFE3C36C)),
                ),
            ],
          ),
          Expanded(
            child: Center(
              child: _buildFrontContent(context),
            ),
          ),
          Text(
            'TAP TO REVEAL',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.primaryContainer.withOpacity(0.7),
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontContent(BuildContext context) {
    final card = widget.card;
    final textTheme = Theme.of(context).textTheme;

    if (card.cardType == CardType.cloze) {
      return ClozeCardWidget(
        text: card.frontText,
        isBack: false,
        style: textTheme.displayLarge,
      );
    } else if (card.cardType == CardType.imageOcclusion && card.extraData != null) {
      try {
        final data = jsonDecode(card.extraData!);
        return ImageOcclusionWidget(
          imagePath: data['imagePath'] as String,
          activeRegion: data['activeRegion'] as Map<String, dynamic>,
          allRegions: data['regions'] as List,
          isBack: false,
        );
      } catch (_) {}
    }

    return Text(
      card.frontText,
      textAlign: TextAlign.center,
      style: textTheme.displayLarge?.copyWith(
        color: AppColors.onSurface,
        fontFamily: 'Manrope',
      ),
    );
  }

  Widget _buildBackSide(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasAudio = _getAudioPath() != null;

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
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hasAudio)
                IconButton(
                  onPressed: _playAudio,
                  icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFE3C36C)),
                ),
            ],
          ),
          Expanded(
            child: Center(
              child: _buildBackContent(context),
            ),
          ),
          const SizedBox(height: 16),
          RatingButtons(onRate: widget.onRate),
        ],
      ),
    );
  }

  Widget _buildBackContent(BuildContext context) {
    final card = widget.card;
    final textTheme = Theme.of(context).textTheme;

    if (card.cardType == CardType.cloze && card.extraData != null) {
      try {
        final data = jsonDecode(card.extraData!);
        final rawText = data['clozeText'] as String? ?? card.frontText;
        final index = data['clozeIndex'] as int?;
        return ClozeCardWidget(
          text: rawText,
          targetIndex: index,
          isBack: true,
          style: textTheme.displayLarge,
        );
      } catch (_) {}
    } else if (card.cardType == CardType.imageOcclusion && card.extraData != null) {
      try {
        final data = jsonDecode(card.extraData!);
        return ImageOcclusionWidget(
          imagePath: data['imagePath'] as String,
          activeRegion: data['activeRegion'] as Map<String, dynamic>,
          allRegions: data['regions'] as List,
          isBack: true,
        );
      } catch (_) {}
    }

    return Text(
      card.backText,
      textAlign: TextAlign.center,
      style: textTheme.displayLarge?.copyWith(
        color: AppColors.primaryContainer,
        fontFamily: 'Manrope',
      ),
    );
  }
}
