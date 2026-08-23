import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import '../../models/source_document.dart';
import 'mcp_source_service.dart';

class LocalFolderService implements McpSourceService {
  final String folderPath;

  LocalFolderService(this.folderPath);

  @override
  String get sourceName => 'Local Folder: $folderPath';

  @override
  Future<List<SourceDocument>> fetchDocuments() async {
    final dir = Directory(folderPath);
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
        } else if (name.endsWith('.pdf')) {
          try {
            final content = await ReadPdfText.getPDFtext(path);
            documents.add(SourceDocument(
              id: uuid.v5(Namespace.url.value, path),
              path: path,
              content: content,
              lastModified: stat.modified,
            ));
          } catch (_) {
            // Ignore unreadable PDFs
          }
        }
      }
    }
    return documents;
  }
}
