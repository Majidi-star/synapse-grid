import '../../models/source_document.dart';

abstract class McpSourceService {
  Future<List<SourceDocument>> fetchDocuments();
  String get sourceName;
}
