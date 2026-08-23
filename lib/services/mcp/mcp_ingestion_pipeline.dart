import 'package:shared_preferences/shared_preferences.dart';
import '../ai_card_generator.dart';
import 'mcp_source_service.dart';

class McpIngestionPipeline {
  final AiCardGenerator _generator;

  McpIngestionPipeline({required AiCardGenerator generator}) : _generator = generator;

  Future<int> ingestFromSource(McpSourceService source, String deckId) async {
    final docs = await source.fetchDocuments();
    if (docs.isEmpty) return 0;

    final prefs = await SharedPreferences.getInstance();
    int newCardsCount = 0;

    for (final doc in docs) {
      final key = 'mcp_sync_${source.sourceName.hashCode}_${doc.path}';
      final lastModifiedStored = prefs.getString(key);
      final currentModified = doc.lastModified.toIso8601String();

      if (lastModifiedStored == currentModified) {
        // Document has not changed since last sync
        continue;
      }

      final content = doc.content.trim();
      if (content.isEmpty) continue;

      try {
        if (content.length > 4000) {
          final chunks = _chunkText(content, 3500);
          for (final chunk in chunks) {
            final cards = await _generator.generateFromText(chunk, deckId);
            newCardsCount += cards.length;
          }
        } else {
          final cards = await _generator.generateFromText(content, deckId);
          newCardsCount += cards.length;
        }

        // Save state on successful parsing
        await prefs.setString(key, currentModified);
      } catch (_) {
        // Fail gracefully per file to let others sync
      }
    }

    return newCardsCount;
  }

  List<String> _chunkText(String text, int maxChunkSize) {
    final List<String> chunks = [];
    int start = 0;
    while (start < text.length) {
      int end = start + maxChunkSize;
      if (end >= text.length) {
        chunks.add(text.substring(start));
        break;
      }
      
      int lastBreak = text.lastIndexOf('\n', end);
      if (lastBreak < start) {
        lastBreak = text.lastIndexOf('. ', end);
      }
      
      if (lastBreak > start) {
        chunks.add(text.substring(start, lastBreak));
        start = lastBreak + 1;
      } else {
        chunks.add(text.substring(start, end));
        start = end;
      }
    }
    return chunks;
  }
}
