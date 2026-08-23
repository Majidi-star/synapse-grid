enum MediaType { image, audio }

class MediaAttachment {
  final String id;
  final String cardId;
  final MediaType type;
  final String fileName;
  final String localPath;
  final int sizeBytes;
  final DateTime createdAt;

  const MediaAttachment({
    required this.id,
    required this.cardId,
    required this.type,
    required this.fileName,
    required this.localPath,
    required this.sizeBytes,
    required this.createdAt,
  });

  factory MediaAttachment.fromMap(Map<String, dynamic> map) {
    return MediaAttachment(
      id: map['id'] as String,
      cardId: map['card_id'] as String,
      type: MediaType.values[map['type'] as int? ?? 0],
      fileName: map['file_name'] as String,
      localPath: map['local_path'] as String,
      sizeBytes: map['size_bytes'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'type': type.index,
      'file_name': fileName,
      'local_path': localPath,
      'size_bytes': sizeBytes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MediaAttachment copyWith({
    String? id,
    String? cardId,
    MediaType? type,
    String? fileName,
    String? localPath,
    int? sizeBytes,
    DateTime? createdAt,
  }) {
    return MediaAttachment(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaAttachment &&
        other.id == id &&
        other.cardId == cardId &&
        other.type == type &&
        other.fileName == fileName &&
        other.localPath == localPath &&
        other.sizeBytes == sizeBytes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        cardId.hashCode ^
        type.hashCode ^
        fileName.hashCode ^
        localPath.hashCode ^
        sizeBytes.hashCode ^
        createdAt.hashCode;
  }
}
