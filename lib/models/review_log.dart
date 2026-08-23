class ReviewLog {
  final String id;
  final String cardId;
  final int rating;
  final int reviewTimeMs;
  final double scheduledDays;
  final double elapsedDays;
  final DateTime reviewedAt;

  const ReviewLog({
    required this.id,
    required this.cardId,
    required this.rating,
    required this.reviewTimeMs,
    required this.scheduledDays,
    required this.elapsedDays,
    required this.reviewedAt,
  });

  factory ReviewLog.fromMap(Map<String, dynamic> map) {
    return ReviewLog(
      id: map['id'] as String,
      cardId: map['card_id'] as String,
      rating: map['rating'] as int,
      reviewTimeMs: map['review_time_ms'] as int,
      scheduledDays: (map['scheduled_days'] as num).toDouble(),
      elapsedDays: (map['elapsed_days'] as num).toDouble(),
      reviewedAt: DateTime.parse(map['reviewed_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'rating': rating,
      'review_time_ms': reviewTimeMs,
      'scheduled_days': scheduledDays,
      'elapsed_days': elapsedDays,
      'reviewed_at': reviewedAt.toIso8601String(),
    };
  }
}
