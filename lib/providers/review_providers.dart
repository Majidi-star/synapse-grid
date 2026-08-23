import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/card.dart';
import 'package:recall_app/services/review_service.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

final dueCardsProvider = FutureProvider.family<List<DueCard>, String>((ref, deckId) async {
  final service = ref.watch(reviewServiceProvider);
  return service.getDueCards(deckId, DateTime.now());
});

final dueCardCountProvider = FutureProvider.family<int, String>((ref, deckId) async {
  final service = ref.watch(reviewServiceProvider);
  return service.getDueCardCount(deckId, DateTime.now());
});

final currentCardIndexProvider = StateProvider<int>((ref) => 0);

final isCardFlippedProvider = StateProvider<bool>((ref) => false);
