import 'package:recall_app/core/database/database_helper.dart';

class StatsService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<({double days, double retention})>> getRetentionCurve(String deckId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT ROUND(elapsed_days) as day_bucket, 
             COUNT(*) as total,
             SUM(CASE WHEN rating >= 3 THEN 1 ELSE 0 END) as successful
      FROM review_logs
      WHERE card_id IN (SELECT id FROM cards WHERE deck_id = ?)
      GROUP BY day_bucket
      HAVING total > 0
      ORDER BY day_bucket ASC
    ''', [deckId]);

    return results.map((row) {
      final double days = (row['day_bucket'] as num?)?.toDouble() ?? 0.0;
      final int total = row['total'] as int? ?? 0;
      final int successful = row['successful'] as int? ?? 0;
      final double retention = total > 0 ? (successful / total) * 100 : 0.0;
      return (days: days, retention: retention);
    }).toList();
  }

  Future<List<({DateTime date, int count})>> getReviewForecast(String deckId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT date(due_date) as date_str, COUNT(*) as count
      FROM scheduler_state
      WHERE due_date IS NOT NULL 
        AND card_id IN (SELECT id FROM cards WHERE deck_id = ?)
        AND date(due_date) >= date('now')
      GROUP BY date_str
      ORDER BY date_str ASC
      LIMIT 30
    ''', [deckId]);

    return results.map((row) {
      final String dateStr = row['date_str'] as String;
      final int count = row['count'] as int? ?? 0;
      return (date: DateTime.parse(dateStr), count: count);
    }).toList();
  }

  Future<Map<DateTime, int>> getHeatmapData({int days = 365}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT date(reviewed_at) as date_str, COUNT(*) as count
      FROM review_logs
      WHERE date(reviewed_at) >= date('now', ?)
      GROUP BY date_str
      ORDER BY date_str ASC
    ''', ['-$days days']);

    final Map<DateTime, int> heatmapMap = {};
    for (final row in results) {
      final String dateStr = row['date_str'] as String;
      final int count = row['count'] as int? ?? 0;
      heatmapMap[DateTime.parse(dateStr)] = count;
    }
    return heatmapMap;
  }
}
