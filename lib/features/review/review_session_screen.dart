import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/models/card.dart';
import 'package:recall_app/services/fsrs_engine.dart';
import 'package:recall_app/providers/review_providers.dart';
import 'widgets/flashcard_widget.dart';
import 'widgets/progress_bar.dart';

class ReviewSessionScreen extends ConsumerStatefulWidget {
  final String deckId;
  final String deckName;

  const ReviewSessionScreen({
    super.key,
    required this.deckId,
    required this.deckName,
  });

  @override
  ConsumerState<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends ConsumerState<ReviewSessionScreen> {
  int _currentCardIndex = 0;
  bool _isFlipped = false;

  void _onRate(int ratingValue) {
    final rating = Rating.values[ratingValue - 1];
    final cardsAsync = ref.read(dueCardsProvider(widget.deckId));
    final cards = cardsAsync.value;
    if (cards != null && _currentCardIndex < cards.length) {
      final dueCard = cards[_currentCardIndex];
      ref.read(reviewServiceProvider).recordReview(
        dueCard.card.id,
        rating,
        0, // elapsed time in ms
        DateTime.now(),
      );

      setState(() {
        _isFlipped = false;
        _currentCardIndex++;
      });
    }
  }

  void _onFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _onPrevious() {
    if (_currentCardIndex > 0) {
      setState(() {
        _isFlipped = false;
        _currentCardIndex--;
      });
    }
  }

  void _onNext() {
    final cardsAsync = ref.read(dueCardsProvider(widget.deckId));
    final cards = cardsAsync.value;
    if (cards != null && _currentCardIndex < cards.length - 1) {
      setState(() {
        _isFlipped = false;
        _currentCardIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(dueCardsProvider(widget.deckId));

    return cardsAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Error loading cards: $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
      data: (cards) {
        // Empty state
        if (cards.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(color: AppColors.onSurface),
            ),
            body: Center(
              child: Text(
                'No cards due',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
          );
        }

        // Completion state
        if (_currentCardIndex >= cards.length) {
          return _buildCompletionView(context, cards.length);
        }

        final DueCard currentCard = cards[_currentCardIndex];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.deckName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    '${cards.length - _currentCardIndex}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                SessionProgressBar(
                  current: _currentCardIndex + 1,
                  total: cards.length,
                  deckName: widget.deckName,
                ),
                const Spacer(),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: FlashcardWidget(
                      card: currentCard.card,
                      isFlipped: _isFlipped,
                      onFlip: _onFlip,
                      onRate: _onRate,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _currentCardIndex > 0 ? _onPrevious : null,
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.onSurface.withValues(
                            alpha: _currentCardIndex > 0 ? 0.6 : 0.2,
                          ),
                        ),
                        iconSize: 24,
                        padding: const EdgeInsets.all(12),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _onFlip,
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.flip,
                                  color: AppColors.onPrimaryContainer,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'FLIP',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: _currentCardIndex < cards.length - 1 ? _onNext : null,
                        icon: Icon(
                          Icons.arrow_forward,
                          color: AppColors.onSurface.withValues(
                            alpha: _currentCardIndex < cards.length - 1 ? 0.6 : 0.2,
                          ),
                        ),
                        iconSize: 24,
                        padding: const EdgeInsets.all(12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionView(BuildContext context, int totalReviewed) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.primaryContainer,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Session Complete',
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You reviewed $totalReviewed cards',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 48),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                side: BorderSide(color: AppColors.onSurface.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Back to Deck'),
            ),
          ],
        ),
      ),
    );
  }
}
