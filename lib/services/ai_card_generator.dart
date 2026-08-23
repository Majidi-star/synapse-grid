import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:recall_app/core/database/database_helper.dart';
import 'ai_service.dart';
import '../models/ai_generation_queue.dart';
import '../models/card.dart';

class AiCardGenerator {
  final DynamicAiService aiService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  AiCardGenerator({required this.aiService});

  Future<List<AiGeneratedCard>> generateFromText(String text, String deckId) async {
    const systemPrompt = '''
You are an expert flashcard generator. Given the text provided by the user, generate high-quality flashcards for spaced repetition study.
For each concept, choose the most appropriate card type:
- "basic": A clear, atomic question on the front, and the direct answer on the back.
- "cloze": A fill-in-the-blanks card using standard {{c1::answer}} syntax.

IMPORTANT RULES:
- Keep cards atomic (one single fact per card).
- Do not create vague or trivial questions.
- Output ONLY a raw valid JSON array of objects. Do not include markdown code block formatting (such as ```json) or any conversational text.

JSON Format:
[
  {
    "type": "basic",
    "front": "What is the primary function of mitochondria?",
    "back": "Cellular energy generation (producing ATP)."
  },
  {
    "type": "cloze",
    "cloze_text": "The {{c1::mitochondria}} is the powerhouse of the cell."
  }
]
''';

    final responseText = await aiService.complete(systemPrompt, text);
    
    var cleanedJson = responseText.trim();
    if (cleanedJson.startsWith('```')) {
      final lines = cleanedJson.split('\n');
      if (lines.first.startsWith('```')) {
        lines.removeAt(0);
      }
      if (lines.isNotEmpty && lines.last.startsWith('```')) {
        lines.removeLast();
      }
      cleanedJson = lines.join('\n').trim();
    }

    final List<dynamic> parsedList = jsonDecode(cleanedJson);
    final List<AiGeneratedCard> generatedCards = [];
    final db = await _dbHelper.database;

    for (final item in parsedList) {
      final typeStr = item['type'] as String? ?? 'basic';
      final cardType = typeStr == 'cloze' ? CardType.cloze : CardType.basic;

      String front = '';
      String back = '';
      String? extraData;

      if (cardType == CardType.cloze) {
        front = item['cloze_text'] as String? ?? '';
      } else {
        front = item['front'] as String? ?? '';
        back = item['back'] as String? ?? '';
      }

      final generated = AiGeneratedCard(
        id: const Uuid().v4(),
        deckId: deckId,
        frontText: front,
        backText: back,
        cardType: cardType,
        extraData: extraData,
        sourceSnippet: text.substring(0, text.length > 200 ? 200 : text.length),
        status: QueueStatus.pending,
        createdAt: DateTime.now(),
      );

      await db.insert('ai_generation_queue', generated.toMap());
      generatedCards.add(generated);
    }

    return generatedCards;
  }

  Future<List<AiGeneratedCard>> getPendingQueue(String deckId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'ai_generation_queue',
      where: 'deck_id = ? AND status = ?',
      whereArgs: [deckId, QueueStatus.pending.index],
    );
    return maps.map((m) => AiGeneratedCard.fromMap(m)).toList();
  }

  Future<void> updateQueueStatus(String cardId, QueueStatus status) async {
    final db = await _dbHelper.database;
    await db.update(
      'ai_generation_queue',
      {'status': status.index},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }
}
