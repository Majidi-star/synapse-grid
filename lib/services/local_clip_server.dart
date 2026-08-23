import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:recall_app/core/database/database_helper.dart';
import 'ai_card_generator.dart';
import 'ai_service.dart';

class LocalClipServer {
  HttpServer? _server;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AiCardGenerator _generator = AiCardGenerator(aiService: DynamicAiService());

  Future<void> start() async {
    if (_server != null) return;

    var handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware)
        .addHandler(_router);

    try {
      _server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 57849);
      debugPrint('Local clip server running on port 57849');
    } catch (e) {
      debugPrint('Failed to start local clip server: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Middleware get _corsMiddleware => (Handler innerHandler) {
        return (Request request) async {
          if (request.method == 'OPTIONS') {
            return Response.ok('', headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
              'Access-Control-Allow-Headers': 'Origin, Content-Type',
            });
          }
          final response = await innerHandler(request);
          return response.change(headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type',
          });
        };
      };

  Future<Response> _router(Request request) async {
    final path = request.url.path;

    if (path == 'decks' && request.method == 'GET') {
      try {
        final db = await _dbHelper.database;
        final List<Map<String, dynamic>> maps = await db.query('decks');
        final decks = maps.map((m) => {
          'id': m['id'],
          'name': m['name'],
        }).toList();
        
        return Response.ok(jsonEncode(decks), headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Failed to retrieve decks: $e');
      }
    }

    if (path == 'clip' && request.method == 'POST') {
      try {
        final bodyStr = await request.readAsString();
        final payload = jsonDecode(bodyStr) as Map<String, dynamic>;
        
        final String? text = payload['selectedText'] as String?;
        final String? deckId = payload['deckId'] as String?;
        final String? url = payload['url'] as String?;
        final String? title = payload['title'] as String?;

        if (text == null || text.trim().isEmpty || deckId == null || deckId.isEmpty) {
          return Response.badRequest(body: 'Missing selectedText or deckId parameters.');
        }

        // Formulate content with reference source info
        final referenceInfo = (url != null && url.isNotEmpty)
            ? '\n\nSource: ${title ?? "Webpage"} ($url)'
            : '';
        final textToIngest = '$text$referenceInfo';

        final generatedCards = await _generator.generateFromText(textToIngest, deckId);
        
        return Response.ok(jsonEncode({
          'success': true,
          'message': 'Clipped content successfully. Generated ${generatedCards.length} review items.',
          'cardCount': generatedCards.length
        }), headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Failed to ingest clipped content: $e');
      }
    }

    return Response.notFound('Not Found');
  }
}

// Simple flutter debug print substitute for shelf
void debugPrint(String message) {
  stdout.writeln('[LocalClipServer] $message');
}
