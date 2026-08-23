import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:recall_app/core/database/database_helper.dart';
import 'package:recall_app/models/card.dart';
import 'package:recall_app/models/study_session_plan.dart';
import 'ai_service.dart';
import 'review_service.dart';

class StudyAgentService {
  final DynamicAiService _aiService;
  final ReviewService _reviewService = ReviewService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  StudyAgentService({required DynamicAiService aiService}) : _aiService = aiService;

  Future<StudySessionPlan> planSession(String deckId, {DateTime? examDate}) async {
    final now = DateTime.now();
    final dueCards = await _reviewService.getDueCards(deckId, now);

    if (dueCards.isEmpty) {
      return StudySessionPlan(
        sessionId: const Uuid().v4(),
        deckId: deckId,
        plannedCardIds: [],
        strategy: 'No cards are currently due for review. Deferring to standard scheduler.',
        examDate: examDate,
        targetRetention: 0.90,
        adaptations: [],
      );
    }

    // Load recent failure details from SQLite to build tutor intelligence context
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> errorLogs = await db.rawQuery('''
      SELECT c.front_text, rl.rating, rl.reviewed_at
      FROM review_logs rl
      INNER JOIN cards c ON rl.card_id = c.id
      WHERE c.deck_id = ? AND rl.rating = 1
      ORDER BY rl.reviewed_at DESC
      LIMIT 10
    ''', [deckId]);

    final errorsSummary = errorLogs.isEmpty
        ? 'No recent review failures logged.'
        : errorLogs.map((l) => '- "${l['front_text']}" was rated AGAIN on ${l['reviewed_at']}').join('\n');

    final cardsData = dueCards.map((dc) => {
      'id': dc.card.id,
      'front': dc.card.frontText,
      'back': dc.card.backText,
      'reps': dc.state.reps,
      'lapses': dc.state.lapses,
    }).toList();

    final systemPrompt = '''
You are an expert Study Coach Agent. Your task is to plan an optimal study session sequence.
Given a list of due cards and a summary of recent review failures (Again ratings), determine:
1. A clear 1-2 sentence study strategy description.
2. The optimal sorting order of these card IDs to maximize retention and interleaving.

Return ONLY a valid JSON object in this format, with no explanation or markdown formatting:
{
  "strategy": "Your study strategy description here.",
  "orderedCardIds": ["id1", "id2", ...]
}
''';

    final userMessage = '''
Deck ID: $deckId
Exam Date: ${examDate?.toIso8601String() ?? 'Not Set'}
Recent Review Failures:
$errorsSummary

Due Cards:
${jsonEncode(cardsData)}
''';

    try {
      final rawResponse = await _aiService.complete(systemPrompt, userMessage);
      var jsonText = rawResponse.trim();
      if (jsonText.startsWith('```')) {
        final lines = jsonText.split('\n');
        if (lines.first.startsWith('```json')) {
          jsonText = lines.sublist(1, lines.length - 1).join('\n');
        } else if (lines.first.startsWith('```')) {
          jsonText = lines.sublist(1, lines.length - 1).join('\n');
        }
      }
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      final orderedIds = List<String>.from(decoded['orderedCardIds'] as List);
      
      // Ensure all due card IDs are preserved (fallback if LLM misses any)
      final allDueIds = dueCards.map((c) => c.card.id).toSet();
      final finalOrderedIds = orderedIds.where((id) => allDueIds.contains(id)).toList();
      final missingIds = allDueIds.difference(finalOrderedIds.toSet());
      finalOrderedIds.addAll(missingIds);

      return StudySessionPlan(
        sessionId: const Uuid().v4(),
        deckId: deckId,
        plannedCardIds: finalOrderedIds,
        strategy: decoded['strategy'] as String? ?? 'Reviewing cards sorted by optimized FSRS order.',
        examDate: examDate,
        targetRetention: 0.90,
        adaptations: [],
      );
    } catch (e) {
      // Fallback
      return StudySessionPlan(
        sessionId: const Uuid().v4(),
        deckId: deckId,
        plannedCardIds: dueCards.map((dc) => dc.card.id).toList(),
        strategy: 'Default scheduler sequence due to planning service timeout.',
        examDate: examDate,
        targetRetention: 0.90,
        adaptations: [],
      );
    }
  }

  Future<StudySessionPlan> adaptSession(
    StudySessionPlan currentPlan,
    List<int> recentRatings,
    List<FlashCard> sessionCards,
  ) async {
    // Check if the user is struggling (e.g. 2 or more AGAIN (1) ratings in the last 5 reviews)
    final againCount = recentRatings.where((r) => r == 1).length;
    if (againCount < 2) {
      // No adaptation needed
      return currentPlan;
    }

    final systemPrompt = '''
You are a study tutor adjusting the study session plan in real-time.
The user is struggling: they rated ${againCount} out of the last ${recentRatings.length} cards as "AGAIN" (failed).
Analyze their session progress and determine:
1. The adaptation reason (why they are struggling).
2. The adaptation action (how we adjust: e.g., re-injecting failed cards sooner, focusing on simpler terms first).
3. The revised remaining card ID order.

Return ONLY a valid JSON object in this format:
{
  "reason": "User is failing to recall concepts related to X...",
  "action": "Prioritizing shorter reviews and placing failed cards 3 steps ahead.",
  "orderedCardIds": ["idA", "idB", ...]
}
''';

    final remainingIds = currentPlan.plannedCardIds;
    final cardDetails = sessionCards.map((c) => {
      'id': c.id,
      'front': c.frontText,
      'back': c.backText,
    }).toList();

    final userMessage = '''
Current Strategy: ${currentPlan.strategy}
Recent Ratings (1=Again, 4=Easy): $recentRatings
Remaining Cards in Queue:
${jsonEncode(cardDetails.where((c) => remainingIds.contains(c['id'])).toList())}
''';

    try {
      final rawResponse = await _aiService.complete(systemPrompt, userMessage);
      var jsonText = rawResponse.trim();
      if (jsonText.startsWith('```')) {
        final lines = jsonText.split('\n');
        if (lines.first.startsWith('```json')) {
          jsonText = lines.sublist(1, lines.length - 1).join('\n');
        } else if (lines.first.startsWith('```')) {
          jsonText = lines.sublist(1, lines.length - 1).join('\n');
        }
      }
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      final newOrderedIds = List<String>.from(decoded['orderedCardIds'] as List);

      // Verify IDs match remaining
      final remainingSet = remainingIds.toSet();
      final validatedOrderedIds = newOrderedIds.where((id) => remainingSet.contains(id)).toList();
      final missingIds = remainingSet.difference(validatedOrderedIds.toSet());
      validatedOrderedIds.addAll(missingIds);

      final adaptation = StudySessionAdaptation(
        triggeredAt: DateTime.now(),
        reason: decoded['reason'] as String? ?? 'User experiencing high recall failure rate.',
        action: decoded['action'] as String? ?? 'Resorting review cards to improve focus.',
      );

      return StudySessionPlan(
        sessionId: currentPlan.sessionId,
        deckId: currentPlan.deckId,
        plannedCardIds: validatedOrderedIds,
        strategy: currentPlan.strategy,
        examDate: currentPlan.examDate,
        targetRetention: currentPlan.targetRetention,
        adaptations: [...currentPlan.adaptations, adaptation],
      );
    } catch (e) {
      // Return original plan on error
      return currentPlan;
    }
  }

  Future<List<FlashCard>> generateWeakSpotCards(String deckId) async {
    final db = await _dbHelper.database;
    
    // Find the top 3 cards with the highest lapses or failures
    final List<Map<String, dynamic>> weakCardsMaps = await db.rawQuery('''
      SELECT c.id, c.front_text, c.back_text, s.lapses
      FROM scheduler_state s
      INNER JOIN cards c ON s.card_id = c.id
      WHERE c.deck_id = ? AND s.lapses > 0
      ORDER BY s.lapses DESC
      LIMIT 3
    ''', [deckId]);

    if (weakCardsMaps.isEmpty) {
      return [];
    }

    final weakCardsSummary = weakCardsMaps.map((m) {
      return '- Front: "${m['front_text']}"\n  Back: "${m['back_text']}"\n  Lapses: ${m['lapses']}';
    }).join('\n\n');

    final systemPrompt = '''
You are a study coach. The user consistently confuses the following concepts.
Generate 2 new comparative or mnemonic flashcards to clarify the exact differences or help memorize these weak spots.
Make the questions simple, clear, and highly focused (Minimum Information Principle).

Return ONLY a valid JSON array of flashcard objects, with no markdown tags or explanation:
[
  {
    "frontText": "How does Concept A differ from Concept B regarding X?",
    "backText": "Concept A is... while Concept B is..."
  },
  {
    "frontText": "Mnemonic helper question...",
    "backText": "Mnemonic explanation..."
  }
]
''';

    final userMessage = 'Here are the weak concept cards the user is struggling with:\n\n$weakCardsSummary';

    try {
      final rawResponse = await _aiService.complete(systemPrompt, userMessage);
      var jsonText = rawResponse.trim();
      if (jsonText.startsWith('```')) {
        final lines = jsonText.split('\n');
        if (lines.first.startsWith('```json')) {
          jsonText = lines.sublist(1, lines.length - 1).join('\n');
        } else if (lines.first.startsWith('```')) {
          jsonText = lines.sublist(1, lines.length - 1).join('\n');
        }
      }
      final List<dynamic> decoded = jsonDecode(jsonText) as List<dynamic>;
      
      final nowStr = DateTime.now().toIso8601String();
      return decoded.map((item) {
        final map = item as Map<String, dynamic>;
        return FlashCard(
          id: const Uuid().v4(),
          deckId: deckId,
          frontText: map['frontText'] as String? ?? '',
          backText: map['backText'] as String? ?? '',
          cardType: CardType.basic,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
