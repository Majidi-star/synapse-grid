import 'package:uuid/uuid.dart';
import 'package:recall_app/core/database/database_helper.dart';
import 'ai_service.dart';
import '../models/chat_message.dart';

class AiTutorService {
  final DynamicAiService aiService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  AiTutorService({required this.aiService});

  Future<String> buildSystemPrompt(String deckId) async {
    final db = await _dbHelper.database;

    // 1. Fetch deck info
    final List<Map<String, dynamic>> deckMaps = await db.query(
      'decks',
      where: 'id = ?',
      whereArgs: [deckId],
    );
    final deckName = deckMaps.isNotEmpty ? deckMaps.first['name'] as String : 'Active Deck';
    final deckDesc = deckMaps.isNotEmpty ? deckMaps.first['description'] as String? ?? '' : '';

    // 2. Fetch stats
    final List<Map<String, dynamic>> cardCountMaps = await db.rawQuery(
      'SELECT COUNT(*) as total FROM cards WHERE deck_id = ?',
      [deckId],
    );
    final totalCards = cardCountMaps.isNotEmpty ? cardCountMaps.first['total'] as int? ?? 0 : 0;

    final List<Map<String, dynamic>> dueCountMaps = await db.rawQuery('''
      SELECT COUNT(*) as due 
      FROM scheduler_state s
      JOIN cards c ON s.card_id = c.id
      WHERE c.deck_id = ? AND s.due_date <= datetime('now')
    ''', [deckId]);
    final dueCards = dueCountMaps.isNotEmpty ? dueCountMaps.first['due'] as int? ?? 0 : 0;

    // 3. Fetch struggled cards (rating = 1)
    final List<Map<String, dynamic>> struggledMaps = await db.rawQuery('''
      SELECT DISTINCT c.front_text, c.back_text
      FROM review_logs r
      JOIN cards c ON r.card_id = c.id
      WHERE c.deck_id = ? AND r.rating = 1
      ORDER BY r.reviewed_at DESC
      LIMIT 5
    ''', [deckId]);

    final struggledList = struggledMaps.map((row) {
      return '- Q: ${row['front_text']} | A: ${row['back_text']}';
    }).join('\n');

    return '''
You are Synap AI, a premium, intelligent study tutor. You are helping the user study and master their flashcard deck.

DECK INFO:
- Name: $deckName
- Description: $deckDesc
- Total cards: $totalCards
- Cards due today: $dueCards

${struggledList.isNotEmpty ? 'RECENTLY STRUGGLED CARDS (Focus areas):\n$struggledList' : ''}

INSTRUCTIONS:
- Guide the user on these topics. Explain difficult concepts clearly, verify their understanding by asking quick follow-up questions, or write example card prompts.
- Use formatting (bullet points, bold text, markdown code blocks) to make responses look extremely structured and beautiful.
- Keep responses relatively concise and focused on high-quality learning. Avoid overly verbose welcomes.
''';
  }

  Future<List<ChatMessage>> getChatHistory(String? deckId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: deckId != null ? 'deck_id = ?' : 'deck_id IS NULL',
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => ChatMessage.fromMap(m)).toList();
  }

  Future<ChatMessage> sendMessage(String deckId, String userContent) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    // 1. Persist user message
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      deckId: deckId,
      role: ChatRole.user,
      content: userContent,
      createdAt: now,
    );
    await db.insert('chat_messages', userMessage.toMap());

    // 2. Fetch history (limit to last 20 for token budget)
    final history = await getChatHistory(deckId);

    // 3. Build system prompt
    final systemPrompt = await buildSystemPrompt(deckId);

    // 4. Call LLM Service
    // Format conversation history into a clean user prompt
    final conversationBuffer = StringBuffer();
    for (final msg in history) {
      final label = msg.role == ChatRole.user ? 'User' : 'Tutor';
      conversationBuffer.writeln('$label: ${msg.content}');
    }
    conversationBuffer.writeln('User: $userContent');

    final reply = await aiService.complete(systemPrompt, conversationBuffer.toString());

    // 5. Persist assistant reply
    final assistantMessage = ChatMessage(
      id: const Uuid().v4(),
      deckId: deckId,
      role: ChatRole.assistant,
      content: reply.trim(),
      createdAt: DateTime.now(),
    );
    await db.insert('chat_messages', assistantMessage.toMap());

    return assistantMessage;
  }

  Future<void> clearHistory(String? deckId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'chat_messages',
      where: deckId != null ? 'deck_id = ?' : 'deck_id IS NULL',
    );
  }
}
