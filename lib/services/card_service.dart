import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:recall_app/core/database/database_helper.dart';
import 'package:recall_app/models/card.dart';
import 'package:recall_app/models/scheduler_state.dart';

class ClozeParser {
  static List<int> getClozeIndices(String text) {
    final regex = RegExp(r'\{\{c(\d+)::');
    final matches = regex.allMatches(text);
    final indices = <int>{};
    for (final m in matches) {
      indices.add(int.parse(m.group(1)!));
    }
    return indices.toList()..sort();
  }

  static String compileFront(String text, int targetIndex) {
    var result = text;
    final allMatchesRegex = RegExp(r'\{\{c(\d+)::(.*?)\}\}');
    
    result = result.replaceAllMapped(allMatchesRegex, (match) {
      final index = int.parse(match.group(1)!);
      final answer = match.group(2)!;
      if (index == targetIndex) {
        return '[...]';
      } else {
        return answer;
      }
    });
    return result;
  }

  static String compileBack(String text, int targetIndex) {
    final allMatchesRegex = RegExp(r'\{\{c(\d+)::(.*?)\}\}');
    final matches = allMatchesRegex.allMatches(text);
    for (final m in matches) {
      final index = int.parse(m.group(1)!);
      if (index == targetIndex) {
        return m.group(2)!;
      }
    }
    return '';
  }
}

class CardService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<FlashCard>> getCardsForDeck(String deckId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'deck_id = ?',
      whereArgs: [deckId],
    );
    return List.generate(maps.length, (i) => FlashCard.fromMap(maps[i]));
  }

  Future<FlashCard> getCard(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return FlashCard.fromMap(maps.first);
    }
    throw Exception('Card not found');
  }

  Future<void> createCard(FlashCard parentCard) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final now = DateTime.now();

      if (parentCard.cardType == CardType.basic) {
        await _insertSingleCard(txn, parentCard, now);
      } else if (parentCard.cardType == CardType.bidirectional) {
        final card1 = parentCard.copyWith(
          id: parentCard.id,
          parentNoteId: parentCard.id,
          updatedAt: now,
        );
        await _insertSingleCard(txn, card1, now);

        final card2 = parentCard.copyWith(
          id: const Uuid().v4(),
          frontText: parentCard.backText,
          backText: parentCard.frontText,
          parentNoteId: parentCard.id,
          updatedAt: now,
        );
        await _insertSingleCard(txn, card2, now);
      } else if (parentCard.cardType == CardType.cloze) {
        final text = parentCard.frontText;
        final indices = ClozeParser.getClozeIndices(text);
        if (indices.isEmpty) {
          await _insertSingleCard(txn, parentCard, now);
          return;
        }

        for (int i = 0; i < indices.length; i++) {
          final index = indices[i];
          final front = ClozeParser.compileFront(text, index);
          final back = ClozeParser.compileBack(text, index);
          final clozeCard = parentCard.copyWith(
            id: i == 0 ? parentCard.id : const Uuid().v4(),
            frontText: front,
            backText: back,
            parentNoteId: parentCard.id,
            extraData: jsonEncode({
              'clozeText': text,
              'clozeIndex': index,
            }),
            updatedAt: now,
          );
          await _insertSingleCard(txn, clozeCard, now);
        }
      } else if (parentCard.cardType == CardType.imageOcclusion) {
        final extraDataMap = jsonDecode(parentCard.extraData ?? '{}');
        final regionsList = extraDataMap['regions'] as List? ?? [];
        if (regionsList.isEmpty) {
          await _insertSingleCard(txn, parentCard, now);
          return;
        }

        for (int i = 0; i < regionsList.length; i++) {
          final region = regionsList[i];
          final occlusionCard = parentCard.copyWith(
            id: i == 0 ? parentCard.id : const Uuid().v4(),
            frontText: parentCard.frontText,
            backText: 'Reveal Mask ${i + 1}',
            parentNoteId: parentCard.id,
            extraData: jsonEncode({
              'imagePath': parentCard.frontText,
              'activeRegion': region,
              'regions': regionsList,
              'regionIndex': i,
            }),
            updatedAt: now,
          );
          await _insertSingleCard(txn, occlusionCard, now);
        }
      }
    });
  }

  Future<void> _insertSingleCard(dynamic txn, FlashCard card, DateTime now) async {
    await txn.insert('cards', card.toMap());
    final state = SchedulerState(
      cardId: card.id,
      stability: 0.0,
      difficulty: 0.0,
      dueDate: now,
      reps: 0,
      lapses: 0,
    );
    await txn.insert('scheduler_state', state.toMap());
  }

  Future<void> updateCard(FlashCard parentCard) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Fetch all existing sibling cards
      final List<Map<String, dynamic>> existingMaps = await txn.query(
        'cards',
        where: 'id = ? OR parent_note_id = ?',
        whereArgs: [parentCard.id, parentCard.id],
      );
      final existingCards = existingMaps.map((m) => FlashCard.fromMap(m)).toList();

      if (existingCards.isEmpty) return;

      // 2. Fetch all scheduling states for these existing cards
      final List<Map<String, dynamic>> existingStates = [];
      for (final card in existingCards) {
        final List<Map<String, dynamic>> statesMaps = await txn.query(
          'scheduler_state',
          where: 'card_id = ?',
          whereArgs: [card.id],
        );
        if (statesMaps.isNotEmpty) {
          existingStates.add(statesMaps.first);
        }
      }

      // 3. Delete existing cards, scheduling states, and review logs
      for (final card in existingCards) {
        await txn.delete('cards', where: 'id = ?', whereArgs: [card.id]);
        await txn.delete('scheduler_state', where: 'card_id = ?', whereArgs: [card.id]);
      }

      // 4. Compile the card again
      final now = DateTime.now();
      final compiledCards = <FlashCard>[];

      if (parentCard.cardType == CardType.basic) {
        compiledCards.add(parentCard.copyWith(updatedAt: now));
      } else if (parentCard.cardType == CardType.bidirectional) {
        compiledCards.add(parentCard.copyWith(id: parentCard.id, parentNoteId: parentCard.id, updatedAt: now));
        compiledCards.add(parentCard.copyWith(
          id: const Uuid().v4(),
          frontText: parentCard.backText,
          backText: parentCard.frontText,
          parentNoteId: parentCard.id,
          updatedAt: now,
        ));
      } else if (parentCard.cardType == CardType.cloze) {
        final text = parentCard.frontText;
        final indices = ClozeParser.getClozeIndices(text);
        if (indices.isEmpty) {
          compiledCards.add(parentCard.copyWith(updatedAt: now));
        } else {
          for (int i = 0; i < indices.length; i++) {
            final index = indices[i];
            final front = ClozeParser.compileFront(text, index);
            final back = ClozeParser.compileBack(text, index);
            compiledCards.add(parentCard.copyWith(
              id: i == 0 ? parentCard.id : const Uuid().v4(),
              frontText: front,
              backText: back,
              parentNoteId: parentCard.id,
              extraData: jsonEncode({
                'clozeText': text,
                'clozeIndex': index,
              }),
              updatedAt: now,
            ));
          }
        }
      } else if (parentCard.cardType == CardType.imageOcclusion) {
        final extraDataMap = jsonDecode(parentCard.extraData ?? '{}');
        final regionsList = extraDataMap['regions'] as List? ?? [];
        if (regionsList.isEmpty) {
          compiledCards.add(parentCard.copyWith(updatedAt: now));
        } else {
          for (int i = 0; i < regionsList.length; i++) {
            final region = regionsList[i];
            compiledCards.add(parentCard.copyWith(
              id: i == 0 ? parentCard.id : const Uuid().v4(),
              frontText: parentCard.frontText,
              backText: 'Reveal Mask ${i + 1}',
              parentNoteId: parentCard.id,
              extraData: jsonEncode({
                'imagePath': parentCard.frontText,
                'activeRegion': region,
                'regions': regionsList,
                'regionIndex': i,
              }),
              updatedAt: now,
            ));
          }
        }
      }

      // 5. Re-insert compiled cards and match scheduling state if possible
      for (int i = 0; i < compiledCards.length; i++) {
        final card = compiledCards[i];
        await txn.insert('cards', card.toMap());

        Map<String, dynamic>? oldStateMap;
        if (i < existingStates.length) {
          oldStateMap = existingStates[i];
        }

        final state = SchedulerState(
          cardId: card.id,
          stability: oldStateMap?['stability'] as double? ?? 0.0,
          difficulty: oldStateMap?['difficulty'] as double? ?? 0.0,
          dueDate: oldStateMap?['due_date'] != null ? DateTime.parse(oldStateMap!['due_date'] as String) : now,
          lastReview: oldStateMap?['last_review'] != null ? DateTime.parse(oldStateMap!['last_review'] as String) : null,
          reps: oldStateMap?['reps'] as int? ?? 0,
          lapses: oldStateMap?['lapses'] as int? ?? 0,
          state: CardState.values[oldStateMap?['state'] as int? ?? 0],
        );
        await txn.insert('scheduler_state', state.toMap());
      }
    });
  }

  Future<void> deleteCard(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Find all sibling/compiled cards
      final List<Map<String, dynamic>> maps = await txn.query(
        'cards',
        where: 'id = ? OR parent_note_id = ?',
        whereArgs: [id, id],
      );
      for (final row in maps) {
        final cardId = row['id'] as String;
        await txn.delete('scheduler_state', where: 'card_id = ?', whereArgs: [cardId]);
        await txn.delete('review_logs', where: 'card_id = ?', whereArgs: [cardId]);
        await txn.delete('cards', where: 'id = ?', whereArgs: [cardId]);
      }
    });
  }
}
