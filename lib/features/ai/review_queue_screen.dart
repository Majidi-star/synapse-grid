import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/providers/ai_providers.dart';
import 'package:recall_app/providers/card_providers.dart';
import 'package:recall_app/providers/deck_providers.dart';
import 'package:recall_app/models/ai_generation_queue.dart';
import 'package:recall_app/models/card.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/core/database/database_helper.dart';

class ReviewQueueScreen extends ConsumerStatefulWidget {
  final String deckId;
  final String deckName;

  const ReviewQueueScreen({
    Key? key,
    required this.deckId,
    required this.deckName,
  }) : super(key: key);

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  final Map<String, bool> _processingItems = {};

  Future<void> _acceptCard(AiGeneratedCard item) async {
    if (_processingItems[item.id] == true) return;
    setState(() {
      _processingItems[item.id] = true;
    });

    try {
      final cardService = ref.read(cardServiceProvider);
      final generator = ref.read(aiCardGeneratorProvider);
      
      final card = FlashCard(
        id: const Uuid().v4(),
        deckId: widget.deckId,
        frontText: item.frontText,
        backText: item.backText,
        cardType: item.cardType,
        extraData: item.extraData,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cardService.createCard(card);
      await generator.updateQueueStatus(item.id, QueueStatus.accepted);

      // Refresh list
      ref.invalidate(aiPendingQueueProvider(widget.deckId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept card: $e')),
      );
    } finally {
      setState(() {
        _processingItems[item.id] = false;
      });
    }
  }

  Future<void> _rejectCard(AiGeneratedCard item) async {
    if (_processingItems[item.id] == true) return;
    setState(() {
      _processingItems[item.id] = true;
    });

    try {
      final generator = ref.read(aiCardGeneratorProvider);
      await generator.updateQueueStatus(item.id, QueueStatus.rejected);
      ref.invalidate(aiPendingQueueProvider(widget.deckId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject card: $e')),
      );
    } finally {
      setState(() {
        _processingItems[item.id] = false;
      });
    }
  }

  Future<void> _acceptAll(List<AiGeneratedCard> items) async {
    final cardService = ref.read(cardServiceProvider);
    final generator = ref.read(aiCardGeneratorProvider);

    setState(() {
      for (var item in items) {
        _processingItems[item.id] = true;
      }
    });

    try {
      for (final item in items) {
        final card = FlashCard(
          id: const Uuid().v4(),
          deckId: widget.deckId,
          frontText: item.frontText,
          backText: item.backText,
          cardType: item.cardType,
          extraData: item.extraData,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await cardService.createCard(card);
        await generator.updateQueueStatus(item.id, QueueStatus.accepted);
      }
      
      final deckService = ref.read(deckServiceProvider);
      await deckService.updateCardCount(widget.deckId);
      ref.refresh(decksProvider);
      ref.refresh(cardsForDeckProvider(widget.deckId));
      ref.invalidate(aiPendingQueueProvider(widget.deckId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept all cards: $e')),
      );
    } finally {
      setState(() {
        _processingItems.clear();
      });
    }
  }

  Future<void> _rejectAll(List<AiGeneratedCard> items) async {
    final generator = ref.read(aiCardGeneratorProvider);

    setState(() {
      for (var item in items) {
        _processingItems[item.id] = true;
      }
    });

    try {
      for (final item in items) {
        await generator.updateQueueStatus(item.id, QueueStatus.rejected);
      }
      ref.invalidate(aiPendingQueueProvider(widget.deckId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject all cards: $e')),
      );
    } finally {
      setState(() {
        _processingItems.clear();
      });
    }
  }

  void _editCard(AiGeneratedCard item) {
    final frontController = TextEditingController(text: item.frontText);
    final backController = TextEditingController(text: item.backText);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: const Text(
            'Edit Generated Card',
            style: TextStyle(fontFamily: 'Manrope', color: AppColors.onSurface),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: frontController,
                  maxLines: null,
                  style: const TextStyle(color: AppColors.onSurface, fontFamily: 'Manrope'),
                  decoration: const InputDecoration(
                    labelText: 'Front / Cloze text',
                    labelStyle: TextStyle(color: AppColors.outline),
                  ),
                ),
                if (item.cardType == CardType.basic) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: backController,
                    maxLines: null,
                    style: const TextStyle(color: AppColors.onSurface, fontFamily: 'Manrope'),
                    decoration: const InputDecoration(
                      labelText: 'Back text',
                      labelStyle: TextStyle(color: AppColors.outline),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.outline)),
            ),
            ElevatedButton(
              onPressed: () async {
                final generator = ref.read(aiCardGeneratorProvider);
                final db = DatabaseHelper.instance;
                final activeDb = await db.database;
                
                await activeDb.update(
                  'ai_generation_queue',
                  {
                    'front_text': frontController.text,
                    'back_text': backController.text,
                  },
                  where: 'id = ?',
                  whereArgs: [item.id],
                );
                
                ref.invalidate(aiPendingQueueProvider(widget.deckId));
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE3C36C),
                foregroundColor: AppColors.background,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGold = Color(0xFFE3C36C);
    const surfaceContainer = Color(0xFF21201B);
    const onSurface = Color(0xFFE7E2DA);
    const onSurfaceVariant = Color(0xFFCFC5B3);

    final queueAsync = ref.watch(aiPendingQueueProvider(widget.deckId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () {
            final deckService = ref.read(deckServiceProvider);
            deckService.updateCardCount(widget.deckId);
            ref.refresh(decksProvider);
            ref.refresh(cardsForDeckProvider(widget.deckId));
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Review Queue',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
        ),
        actions: [
          queueAsync.when(
            data: (items) {
              if (items.isEmpty) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    onPressed: () => _rejectAll(items),
                    icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                    tooltip: 'Reject All',
                  ),
                  IconButton(
                    onPressed: () => _acceptAll(items),
                    icon: const Icon(Icons.check_rounded, color: Colors.greenAccent),
                    tooltip: 'Accept All',
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: queueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: primaryGold)),
        error: (err, stack) => Center(child: Text('Error loading queue: $err', style: const TextStyle(color: Colors.red))),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_rounded, size: 72, color: primaryGold),
                  const SizedBox(height: 16),
                  const Text(
                    'Queue Cleared',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All generated cards reviewed.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      final deckService = ref.read(deckServiceProvider);
                      deckService.updateCardCount(widget.deckId);
                      ref.refresh(decksProvider);
                      ref.refresh(cardsForDeckProvider(widget.deckId));
                      Navigator.pop(context); // Go back to deck generator screen
                      Navigator.pop(context); // Go back to deck detail screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Return to Deck',
                      style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isCloze = item.cardType == CardType.cloze;
              final isProcessing = _processingItems[item.id] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: onSurface.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCloze ? const Color(0xFFB9C3FF).withOpacity(0.1) : primaryGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCloze ? 'CLOZE' : 'BASIC',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCloze ? const Color(0xFFB9C3FF) : primaryGold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: isProcessing ? null : () => _editCard(item),
                          icon: const Icon(Icons.edit_rounded, size: 18, color: onSurfaceVariant),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'FRONT',
                      style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.frontText,
                      style: const TextStyle(fontFamily: 'Manrope', color: onSurface, fontSize: 15),
                    ),
                    if (!isCloze) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'BACK',
                        style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.backText,
                        style: const TextStyle(fontFamily: 'Manrope', color: primaryGold, fontSize: 15),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: isProcessing ? null : () => _rejectCard(item),
                          icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                          label: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontFamily: 'Geist')),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: isProcessing ? null : () => _acceptCard(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent.withOpacity(0.1),
                            foregroundColor: Colors.greenAccent,
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Accept', style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
