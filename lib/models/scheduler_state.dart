enum CardState {
  newCard,
  learning,
  review,
  relearning,
}

class SchedulerState {
  final String cardId;
  final double stability;
  final double difficulty;
  final DateTime dueDate;
  final DateTime? lastReview;
  final int reps;
  final int lapses;
  final CardState state;

  const SchedulerState({
    required this.cardId,
    required this.stability,
    required this.difficulty,
    required this.dueDate,
    this.lastReview,
    this.reps = 0,
    this.lapses = 0,
    this.state = CardState.newCard,
  });

  factory SchedulerState.fromMap(Map<String, dynamic> map) {
    return SchedulerState(
      cardId: map['card_id'] as String,
      stability: (map['stability'] as num).toDouble(),
      difficulty: (map['difficulty'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date'] as String),
      lastReview: map['last_review'] != null 
          ? DateTime.parse(map['last_review'] as String) 
          : null,
      reps: map['reps'] as int? ?? 0,
      lapses: map['lapses'] as int? ?? 0,
      state: CardState.values[map['state'] as int? ?? 0],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'card_id': cardId,
      'stability': stability,
      'difficulty': difficulty,
      'due_date': dueDate.toIso8601String(),
      'last_review': lastReview?.toIso8601String(),
      'reps': reps,
      'lapses': lapses,
      'state': state.index,
    };
  }

  SchedulerState copyWith({
    String? cardId,
    double? stability,
    double? difficulty,
    DateTime? dueDate,
    DateTime? lastReview,
    int? reps,
    int? lapses,
    CardState? state,
  }) {
    return SchedulerState(
      cardId: cardId ?? this.cardId,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      dueDate: dueDate ?? this.dueDate,
      lastReview: lastReview ?? this.lastReview,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      state: state ?? this.state,
    );
  }
}
