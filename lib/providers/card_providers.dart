import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/card.dart';
import 'package:recall_app/services/card_service.dart';

final cardServiceProvider = Provider<CardService>((ref) {
  return CardService();
});

final cardsForDeckProvider = FutureProvider.family<List<FlashCard>, String>((ref, deckId) async {
  final service = ref.watch(cardServiceProvider);
  return service.getCardsForDeck(deckId);
});
