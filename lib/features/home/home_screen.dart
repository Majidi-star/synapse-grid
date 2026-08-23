import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/core/router/app_router.dart';
import 'package:recall_app/providers/deck_providers.dart';
import 'package:recall_app/models/deck.dart';
import 'package:recall_app/services/deck_service.dart';

import 'package:recall_app/providers/review_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.outline),
            tooltip: 'Settings',
            onPressed: () => AppRouter.goToSettings(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _currentIndex == 0
          ? RefreshIndicator(
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
            )
          : _currentIndex == 1
              ? _buildLibraryTab(context)
              : _buildProfileTab(context),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => AppRouter.goToCreateDeck(context),
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: AppColors.background),
            )
          : null,
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
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
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
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    title: const Text('Delete Deck', style: TextStyle(color: AppColors.onSurface)),
                    content: Text(
                      'Delete "${deck.name}" and all its cards? This cannot be undone.',
                      style: const TextStyle(color: AppColors.outline),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.outline)),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await DeckService().deleteDeck(deck.id);
                          ref.invalidate(decksProvider);
                        },
                        child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
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

  Widget _buildLibraryTab(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.import_contacts, size: 64, color: AppColors.outline),
          const SizedBox(height: 16),
          Text(
            'Community Decks',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const SizedBox(height: 32),
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.surfaceContainerHigh,
            child: const Icon(Icons.person, size: 40, color: AppColors.outline),
          ),
        ),
        const SizedBox(height: 24),
        _buildProfileTile(
          context,
          icon: Icons.settings,
          label: 'Settings',
          onTap: () => AppRouter.goToSettings(context),
        ),
      ],
    );
  }

  Widget _buildProfileTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurface,
            )),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
