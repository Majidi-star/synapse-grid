import 'package:recall_app/core/database/database_helper.dart';
import 'package:recall_app/models/card.dart';
import 'package:recall_app/models/scheduler_state.dart';
import 'package:recall_app/models/review_log.dart';
import 'package:recall_app/services/fsrs_engine.dart';

class ReviewService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FSRSEngine _engine = FSRSEngine();

  Future<List<DueCard>> getDueCards(String deckId, DateTime now) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        s.stability, s.difficulty, s.due_date, s.last_review, s.reps, s.lapses, s.state,
        c.id as card_id, c.id as id, c.deck_id, c.front_text, c.back_text, c.created_at, c.updated_at
      FROM scheduler_state s
      INNER JOIN cards c ON s.card_id = c.id
      WHERE c.deck_id = ? AND s.due_date <= ?
      ORDER BY s.due_date ASC
    ''', [deckId, now.toIso8601String()]);

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return DueCard(
        card: FlashCard.fromMap(map),
        state: SchedulerState.fromMap(map),
      );
    });
  }

  Future<int> getDueCardCount(String deckId, DateTime now) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM scheduler_state s
      INNER JOIN cards c ON s.card_id = c.id
      WHERE c.deck_id = ? AND s.due_date <= ?
    ''', [deckId, now.toIso8601String()]);

    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> recordReview(String cardId, Rating rating, int reviewTimeMs, DateTime now) async {
    final db = await _dbHelper.database;

    final stateMaps = await db.query(
      'scheduler_state',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );

    if (stateMaps.isEmpty) throw Exception('Scheduler state not found');
    final currentState = SchedulerState.fromMap(stateMaps.first);

    final cards = _engine.repeat(currentState, now);
    SchedulingResult result;

    switch (rating) {
      case Rating.again: result = cards.again;
      case Rating.hard: result = cards.hard;
      case Rating.good: result = cards.good;
      case Rating.easy: result = cards.easy;
    }

    final ReviewLog finalLog = ReviewLog(
      id: result.log.id,
      cardId: result.log.cardId,
      rating: result.log.rating,
      reviewTimeMs: reviewTimeMs,
      elapsedDays: result.log.elapsedDays,
      scheduledDays: result.log.scheduledDays,
      reviewedAt: result.log.reviewedAt,
    );

    await db.transaction((txn) async {
      await txn.update(
        'scheduler_state',
        result.state.toMap(),
        where: 'card_id = ?',
        whereArgs: [result.state.cardId],
      );
      await txn.insert('review_logs', finalLog.toMap());
    });
  }

  Future<Map<CardState, int>> getMasteryBreakdown(String deckId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT s.state, COUNT(*) as count
      FROM scheduler_state s
      INNER JOIN cards c ON s.card_id = c.id
      WHERE c.deck_id = ?
      GROUP BY s.state
    ''', [deckId]);

    final Map<CardState, int> breakdown = {
      for (var s in CardState.values) s: 0,
    };

    for (var row in maps) {
      final stateIndex = row['state'] as int;
      final count = row['count'] as int;
      if (stateIndex >= 0 && stateIndex < CardState.values.length) {
        breakdown[CardState.values[stateIndex]] = count;
      }
    }

    return breakdown;
  }

  Future<int> getStreak() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT date(reviewed_at) as review_date 
      FROM review_logs 
      ORDER BY review_date DESC
    ''');

    if (maps.isEmpty) return 0;

    int streak = 0;
    DateTime currentCheck = DateTime.now();

    for (var row in maps) {
      final reviewDateStr = row['review_date'] as String;
      final reviewDate = DateTime.parse(reviewDateStr);
      final diff = DateTime(currentCheck.year, currentCheck.month, currentCheck.day)
          .difference(DateTime(reviewDate.year, reviewDate.month, reviewDate.day)).inDays;

      if (diff == 0 || diff == 1) {
        streak++;
        currentCheck = reviewDate;
      } else if (diff > 1) {
        break;
      }
    }

    return streak;
  }

  Future<double> getAverageSpeed(String deckId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT AVG(r.review_time_ms) as avg_speed 
      FROM review_logs r
      INNER JOIN cards c ON r.card_id = c.id
      WHERE c.deck_id = ? AND r.review_time_ms IS NOT NULL
    ''', [deckId]);

    final val = result.first['avg_speed'];
    if (val == null) return 0.0;
    return (val as num).toDouble();
  }

  Future<double> getRetentionRate(String deckId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        CAST(SUM(CASE WHEN r.rating >= 3 THEN 1 ELSE 0 END) AS REAL) / 
        CAST(COUNT(*) AS REAL) as retention
      FROM review_logs r
      INNER JOIN cards c ON r.card_id = c.id
      WHERE c.deck_id = ?
    ''', [deckId]);

    final val = result.first['retention'];
    if (val == null) return 0.0;
    return (val as num).toDouble();
  }

  Future<List<int>> getWeeklyActivity() async {
    final db = await _dbHelper.database;
    final List<int> activity = List.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);

      final result = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM review_logs 
        WHERE date(reviewed_at) = ?
      ''', [dateStr]);

      activity[6 - i] = (result.first['count'] as int?) ?? 0;
    }

    return activity;
  }
}
