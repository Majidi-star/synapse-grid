import 'package:recall_app/core/database/database_helper.dart';
import 'package:recall_app/models/card.dart';
import 'package:recall_app/models/scheduler_state.dart';
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

  Future<void> createCard(FlashCard card) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.insert('cards', card.toMap());

      final state = SchedulerState(
        cardId: card.id,
        stability: 0.0,
        difficulty: 0.0,
        dueDate: DateTime.now(),
        reps: 0,
        lapses: 0,
      );

      await txn.insert('scheduler_state', state.toMap());
    });
  }

  Future<void> updateCard(FlashCard card) async {
    final db = await _dbHelper.database;
    await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> deleteCard(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('scheduler_state', where: 'card_id = ?', whereArgs: [id]);
      await txn.delete('review_logs', where: 'card_id = ?', whereArgs: [id]);
      await txn.delete('cards', where: 'id = ?', whereArgs: [id]);
    });
  }
}
