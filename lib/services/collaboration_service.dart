import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/deck.dart';
import '../models/card.dart';
import 'deck_service.dart';
import 'card_service.dart';

class CollaborationService {
  final DeckService _deckService = DeckService();
  final CardService _cardService = CardService();

  Future<String> exportDeckToBase64(String deckId) async {
    final deck = await _deckService.getDeck(deckId);
    final cards = await _cardService.getCardsForDeck(deckId);

    // Filter to only parent cards to prevent sibling duplication during compile
    final parentCards = cards.where((c) => c.parentNoteId == null || c.parentNoteId == c.id).toList();

    final data = {
      'version': 1,
      'deckName': deck.name,
      'deckDescription': deck.description,
      'cards': parentCards.map((c) => {
        'frontText': c.frontText,
        'backText': c.backText,
        'cardType': c.cardType.index,
        'extraData': c.extraData,
      }).toList(),
    };

    final jsonStr = jsonEncode(data);
    final bytes = utf8.encode(jsonStr);
    final compressedBytes = gzip.encode(bytes);
    return base64.encode(compressedBytes);
  }

  Future<Deck> importDeckFromBase64(String base64String) async {
    final compressedBytes = base64.decode(base64String.trim());
    final bytes = gzip.decode(compressedBytes);
    final jsonStr = utf8.decode(bytes);
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    final deckId = const Uuid().v4();
    final deck = Deck(
      id: deckId,
      name: '${data['deckName']} (Shared)',
      description: data['deckDescription'] as String? ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      cardCount: 0,
    );

    await _deckService.createDeck(deck);

    final rawCards = data['cards'] as List<dynamic>;
    for (final item in rawCards) {
      final map = item as Map<String, dynamic>;
      final card = FlashCard(
        id: const Uuid().v4(),
        deckId: deckId,
        frontText: map['frontText'] as String,
        backText: map['backText'] as String,
        cardType: CardType.values[map['cardType'] as int? ?? 0],
        extraData: map['extraData'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _cardService.createCard(card);
    }

    await _deckService.updateCardCount(deckId);
    return _deckService.getDeck(deckId);
  }
}
