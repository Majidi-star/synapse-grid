import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/deck.dart';
import 'package:recall_app/services/deck_service.dart';

final deckServiceProvider = Provider<DeckService>((ref) {
  return DeckService();
});

final decksProvider = FutureProvider<List<Deck>>((ref) async {
  final service = ref.watch(deckServiceProvider);
  return service.getAllDecks();
});

final deckProvider = FutureProvider.family<Deck, String>((ref, id) async {
  final service = ref.watch(deckServiceProvider);
  return service.getDeck(id);
});
