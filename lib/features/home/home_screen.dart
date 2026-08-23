import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/core/router/app_router.dart';
import 'package:recall_app/providers/deck_providers.dart';
import 'package:recall_app/models/deck.dart';

import 'package:recall_app/providers/review_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  
  // The rest of class is skipped for now, will replace _buildDeckList below


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsyncValue = ref.watch(decksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Synap',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // ignore: unused_result
          ref.refresh(decksProvider);
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceContainerHigh,
        child: decksAsyncValue.when(
          data: (decks) {
            if (decks.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildDeckList(context, decks);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stackTrace) => Center(
            child: Text(
              'Error loading decks',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AppRouter.goToCreateDeck(context),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AppColors.background,
              AppColors.background.withOpacity(0.0),
            ],
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.outline,
          currentIndex: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.style),
              label: 'Decks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.import_contacts),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Icon(
            Icons.style,
            size: 64,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Create your first deck',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeckList(BuildContext context, List<Deck> decks) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: decks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final deck = decks[index];

        return Consumer(
          builder: (context, ref, child) {
            final dueCountAsync = ref.watch(dueCardCountProvider(deck.id));
            final dueCount = dueCountAsync.value ?? 0;

            return InkWell(
              onTap: () => AppRouter.goToDeckDetail(context, deck.id, deck.name),
              onLongPress: () {
                // Show delete confirmation
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${deck.cardCount} cards',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.outline,
                              ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$dueCount due',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: dueCount > 0 ? AppColors.primary : AppColors.outline,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
