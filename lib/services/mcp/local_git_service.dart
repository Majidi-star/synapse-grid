import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../models/source_document.dart';
import 'mcp_source_service.dart';

class LocalGitService implements McpSourceService {
  final String repoPath;

  LocalGitService(this.repoPath);

  @override
  String get sourceName => 'Git Repo: $repoPath';

  @override
  Future<List<SourceDocument>> fetchDocuments() async {
    final dir = Directory(repoPath);
    if (!await dir.exists()) {
      return [];
    }

    final documents = <SourceDocument>[];
    final entities = await dir.list(recursive: true).toList();
    final uuid = const Uuid();

    for (final entity in entities) {
      if (entity is File) {
        final path = entity.path;
        final name = path.toLowerCase();
        
        // Skip .git directory and internal files
        final separator = Platform.pathSeparator;
        if (path.contains('${separator}.git${separator}') || 
            path.endsWith('${separator}.git') ||
            path.contains('${separator}.dart_tool${separator}') ||
            path.contains('${separator}.idea${separator}') ||
            path.contains('${separator}build${separator}')) {
          continue;
        }

        final stat = await entity.stat();
        if (name.endsWith('.md') || name.endsWith('.txt')) {
          try {
            final content = await entity.readAsString();
            documents.add(SourceDocument(
              id: uuid.v5(Namespace.url.value, path),
              path: path,
              content: content,
              lastModified: stat.modified,
            ));
          } catch (_) {
            // Ignore decoding failures
          }
        }
      }
    }
    return documents;
  }
}
