import 'package:recall_app/core/database/database_helper.dart';
import 'package:recall_app/models/deck.dart';
import 'package:sqflite/sqflite.dart';

class DeckService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Deck>> getAllDecks() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('decks');
    return List.generate(maps.length, (i) => Deck.fromMap(maps[i]));
  }

  Future<Deck> getDeck(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'decks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Deck.fromMap(maps.first);
    }
    throw Exception('Deck not found');
  }

  Future<void> createDeck(Deck deck) async {
    final db = await _dbHelper.database;
    await db.insert('decks', deck.toMap());
  }

  Future<void> updateDeck(Deck deck) async {
    final db = await _dbHelper.database;
    await db.update(
      'decks',
      deck.toMap(),
      where: 'id = ?',
      whereArgs: [deck.id],
    );
  }

  Future<void> deleteDeck(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('cards', where: 'deck_id = ?', whereArgs: [id]);
      await txn.delete('decks', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> updateCardCount(String deckId) async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cards WHERE deck_id = ?', [deckId]),
    ) ?? 0;

    await db.update(
      'decks',
      {'card_count': count},
      where: 'id = ?',
      whereArgs: [deckId],
    );
  }
}
