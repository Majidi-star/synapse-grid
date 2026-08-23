import 'scheduler_state.dart';

enum CardType {
  basic,
  cloze,
  bidirectional,
  imageOcclusion,
}

class FlashCard {
  final String id;
  final String deckId;
  final String frontText;
  final String backText;
  final CardType cardType;
  final String? extraData;
  final String? parentNoteId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FlashCard({
    required this.id,
    required this.deckId,
    required this.frontText,
    required this.backText,
    this.cardType = CardType.basic,
    this.extraData,
    this.parentNoteId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlashCard.fromMap(Map<String, dynamic> map) {
    return FlashCard(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      frontText: map['front_text'] as String,
      backText: map['back_text'] as String,
      cardType: CardType.values[map['card_type'] as int? ?? 0],
      extraData: map['extra_data'] as String?,
      parentNoteId: map['parent_note_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
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
      'parent_note_id': parentNoteId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FlashCard copyWith({
    String? id,
    String? deckId,
    String? frontText,
    String? backText,
    CardType? cardType,
    String? extraData,
    String? parentNoteId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashCard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      frontText: frontText ?? this.frontText,
      backText: backText ?? this.backText,
      cardType: cardType ?? this.cardType,
      extraData: extraData ?? this.extraData,
      parentNoteId: parentNoteId ?? this.parentNoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FlashCard(id: $id, deckId: $deckId, frontText: $frontText, backText: $backText, cardType: $cardType, extraData: $extraData, parentNoteId: $parentNoteId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is FlashCard &&
      other.id == id &&
      other.deckId == deckId &&
      other.frontText == frontText &&
      other.backText == backText &&
      other.cardType == cardType &&
      other.extraData == extraData &&
      other.parentNoteId == parentNoteId &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      deckId.hashCode ^
      frontText.hashCode ^
      backText.hashCode ^
      cardType.hashCode ^
      extraData.hashCode ^
      parentNoteId.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }
}

class DueCard {
  final FlashCard card;
  final SchedulerState state;

  const DueCard({required this.card, required this.state});
}
