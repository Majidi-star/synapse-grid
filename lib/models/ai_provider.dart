class AiProvider {
  final String id;
  final String name;
  final String providerType; // 'openai', 'anthropic', 'gemini', 'ollama'
  final String? baseUrl;
  final String? apiKey;
  final String? selectedModel;
  final bool isActive;
  final DateTime createdAt;

  const AiProvider({
    required this.id,
    required this.name,
    required this.providerType,
    this.baseUrl,
    this.apiKey,
    this.selectedModel,
    this.isActive = false,
    required this.createdAt,
  });

  factory AiProvider.fromMap(Map<String, dynamic> map) {
    return AiProvider(
      id: map['id'] as String,
      name: map['name'] as String,
      providerType: map['provider_type'] as String,
      baseUrl: map['base_url'] as String?,
      apiKey: map['api_key'] as String?,
      selectedModel: map['selected_model'] as String?,
      isActive: (map['is_active'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'provider_type': providerType,
      'base_url': baseUrl,
      'api_key': apiKey,
      'selected_model': selectedModel,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AiProvider copyWith({
    String? id,
    String? name,
    String? providerType,
    String? baseUrl,
    String? apiKey,
    String? selectedModel,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AiProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      providerType: providerType ?? this.providerType,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiProvider &&
        other.id == id &&
        other.name == name &&
        other.providerType == providerType &&
        other.baseUrl == baseUrl &&
        other.apiKey == apiKey &&
        other.selectedModel == selectedModel &&
        other.isActive == isActive &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        providerType.hashCode ^
        baseUrl.hashCode ^
        apiKey.hashCode ^
        selectedModel.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode;
  }
}
