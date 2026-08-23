import 'dart:convert';

class StudySessionPlan {
  final String sessionId;
  final String deckId;
  final List<String> plannedCardIds;
  final String strategy;
  final DateTime? examDate;
  final double targetRetention;
  final List<StudySessionAdaptation> adaptations;

  StudySessionPlan({
    required this.sessionId,
    required this.deckId,
    required this.plannedCardIds,
    required this.strategy,
    this.examDate,
    required this.targetRetention,
    required this.adaptations,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'deckId': deckId,
      'plannedCardIds': jsonEncode(plannedCardIds),
      'strategy': strategy,
      'examDate': examDate?.toIso8601String(),
      'targetRetention': targetRetention,
      'adaptations': jsonEncode(adaptations.map((a) => a.toMap()).toList()),
    };
  }

  factory StudySessionPlan.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawAdaptations = jsonDecode(map['adaptations'] as String) as List<dynamic>;
    return StudySessionPlan(
      sessionId: map['sessionId'] as String,
      deckId: map['deckId'] as String,
      plannedCardIds: List<String>.from(jsonDecode(map['plannedCardIds'] as String) as List),
      strategy: map['strategy'] as String,
      examDate: map['examDate'] != null ? DateTime.parse(map['examDate'] as String) : null,
      targetRetention: (map['targetRetention'] as num).toDouble(),
      adaptations: rawAdaptations.map((a) => StudySessionAdaptation.fromMap(a as Map<String, dynamic>)).toList(),
    );
  }
}

class StudySessionAdaptation {
  final DateTime triggeredAt;
  final String reason;
  final String action;

  StudySessionAdaptation({
    required this.triggeredAt,
    required this.reason,
    required this.action,
  });

  Map<String, dynamic> toMap() {
    return {
      'triggeredAt': triggeredAt.toIso8601String(),
      'reason': reason,
      'action': action,
    };
  }

  factory StudySessionAdaptation.fromMap(Map<String, dynamic> map) {
    return StudySessionAdaptation(
      triggeredAt: DateTime.parse(map['triggeredAt'] as String),
      reason: map['reason'] as String,
      action: map['action'] as String,
    );
  }
}
