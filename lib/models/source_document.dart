class SourceDocument {
  final String id;
  final String path;
  final String content;
  final DateTime lastModified;

  SourceDocument({
    required this.id,
    required this.path,
    required this.content,
    required this.lastModified,
  });
}
