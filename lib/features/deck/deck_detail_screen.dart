import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/core/router/app_router.dart';
import 'package:recall_app/providers/card_providers.dart';

class DeckDetailScreen extends ConsumerWidget {
  final String deckId;
  final String deckName;

  const DeckDetailScreen({
    super.key,
    required this.deckId,
    required this.deckName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsyncValue = ref.watch(cardsForDeckProvider(deckId));
    final dueCards = 10; // Mock due cards

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          deckName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_rounded, color: Color(0xFFE3C36C)),
            tooltip: 'AI Generate Cards',
            onPressed: () => AppRouter.goToAiGenerate(context, deckId, deckName),
          ),
          IconButton(
            icon: const Icon(Icons.forum_rounded, color: Color(0xFFE3C36C)),
            tooltip: 'AI Tutor Chat',
            onPressed: () => AppRouter.goToChat(context, deckId, deckName),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFFE3C36C)),
            tooltip: 'Statistics',
            onPressed: () => AppRouter.goToStats(context, deckId, deckName),
          ),
          IconButton(
            icon: const Icon(Icons.quiz_rounded, color: Color(0xFFE3C36C)),
            tooltip: 'Practice Exam',
            onPressed: () => AppRouter.goToPracticeExam(context, deckId, deckName),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFFE3C36C)),
            tooltip: 'Share & Sync',
            onPressed: () => AppRouter.goToDeckShare(context, deckId, deckName),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildStatsSummary(context),
          const SizedBox(height: 16),
          Expanded(
            child: cardsAsyncValue.when(
              data: (cards) {
                if (cards.isEmpty) {
                  return Center(
                    child: Text(
                      'No cards yet. Tap + to add.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.outline,
                          ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: cards.length,
                  separatorBuilder: (context, index) => Divider(
                    color: AppColors.outlineVariant,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        card.frontText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurface,
                            ),
                      ),
                      onTap: () => AppRouter.goToEditCard(context, card),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stackTrace) => Center(
                child: Text('Error loading cards', style: TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AppRouter.goToCreateCard(context, deckId),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      bottomNavigationBar: dueCards > 0
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => AppRouter.goToReviewSession(
                        context,
                        deckId,
                        deckName,
                        isAgentic: true,
                      ),
                      icon: const Icon(Icons.psychology_rounded, color: AppColors.primaryContainer),
                      label: Text(
                        'START AGENTIC SESSION',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primaryContainer,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryContainer),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => AppRouter.goToReviewSession(context, deckId, deckName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'REVIEW $dueCards CARDS',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.background,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildStatsSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatChip(context, 'Total', '20'),
          _buildStatChip(context, 'Due', '10'),
          _buildStatChip(context, 'Mastery', '85%'),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.outline,
                ),
          ),
        ],
      ),
    );
  }
}
