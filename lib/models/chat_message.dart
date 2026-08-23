enum ChatRole { user, assistant, system }

class ChatMessage {
  final String id;
  final String? deckId;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    this.deckId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      deckId: map['deck_id'] as String?,
      role: ChatRole.values.firstWhere((e) => e.toString().split('.').last == map['role']),
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'role': role.toString().split('.').last,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
