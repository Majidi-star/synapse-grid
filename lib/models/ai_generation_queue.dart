import 'card.dart';

enum QueueStatus { pending, accepted, rejected }

class AiGeneratedCard {
  final String id;
  final String deckId;
  final String frontText;
  final String backText;
  final CardType cardType;
  final String? extraData;
  final String? sourceSnippet;
  final QueueStatus status;
  final DateTime createdAt;

  const AiGeneratedCard({
    required this.id,
    required this.deckId,
    required this.frontText,
    required this.backText,
    required this.cardType,
    this.extraData,
    this.sourceSnippet,
    this.status = QueueStatus.pending,
    required this.createdAt,
  });

  factory AiGeneratedCard.fromMap(Map<String, dynamic> map) {
    return AiGeneratedCard(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      frontText: map['front_text'] as String,
      backText: map['back_text'] as String,
      cardType: CardType.values[map['card_type'] as int? ?? 0],
      extraData: map['extra_data'] as String?,
      sourceSnippet: map['source_snippet'] as String?,
      status: QueueStatus.values[map['status'] as int? ?? 0],
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'front_text': frontText,
      'back_text': backText,
      'card_type': cardType.index,
      'extra_data': extraData,
      'source_snippet': sourceSnippet,
      'status': status.index,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AiGeneratedCard copyWith({
    String? id,
    String? deckId,
    String? frontText,
    String? backText,
    CardType? cardType,
    String? extraData,
    String? sourceSnippet,
    QueueStatus? status,
    DateTime? createdAt,
  }) {
    return AiGeneratedCard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      frontText: frontText ?? this.frontText,
      backText: backText ?? this.backText,
      cardType: cardType ?? this.cardType,
      extraData: extraData ?? this.extraData,
      sourceSnippet: sourceSnippet ?? this.sourceSnippet,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
