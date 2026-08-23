import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/practice_exam.dart';
import 'ai_service.dart';
import 'card_service.dart';

class PracticeExamService {
  final DynamicAiService _aiService;
  final CardService _cardService = CardService();

  PracticeExamService({required DynamicAiService this._aiService});

  Future<PracticeExam> generateExam(
    String deckId, {
    int questionCount = 5,
    int timeLimitMinutes = 10,
    List<String> types = const ['MC', 'TF', 'ShortAnswer'],
  }) async {
    final cards = await _cardService.getCardsForDeck(deckId);
    if (cards.isEmpty) {
      throw Exception('Cannot generate an exam for an empty deck.');
    }

    // Prepare card summary for LLM context
    final cardsSummary = cards.asMap().entries.map((e) {
      final i = e.key + 1;
      final c = e.value;
      return 'Card $i (Type: ${c.cardType.name}):\nFront: ${c.frontText}\nBack: ${c.backText}';
    }).join('\n\n');

    final systemPrompt = '''
You are an advanced exam generator for a spaced repetition system.
Given a list of flashcards, generate $questionCount practice exam questions covering the card concepts.
Use the following allowed question types: ${types.join(', ')}.

Ensure that:
1. MC (Multiple Choice) questions have exactly 4 options.
2. TF (True/False) questions have exactly 2 options: ["True", "False"], and the correctAnswer must be exactly "True" or "False".
3. ShortAnswer questions ask for a concept definition or explanation, with options set to null, and the correctAnswer represents a model concise answer.

Return ONLY a valid JSON array of question objects, with no markdown wrappers or explanation.
Format:
[
  {
    "type": "MC",
    "questionText": "Question text here?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswer": "Option A"
  },
  {
    "type": "TF",
    "questionText": "Statement to evaluate...",
    "options": ["True", "False"],
    "correctAnswer": "True"
  },
  {
    "type": "ShortAnswer",
    "questionText": "Explain concept...",
    "options": null,
    "correctAnswer": "Model answer explanation"
  }
]
''';

    final userMessage = 'Here are the flashcards to generate the exam from:\n\n$cardsSummary';

    final rawResponse = await _aiService.complete(systemPrompt, userMessage);
    
    // Clean potential markdown formatting from LLM response
    var jsonText = rawResponse.trim();
    if (jsonText.startsWith('```')) {
      final lines = jsonText.split('\n');
      if (lines.first.startsWith('```json')) {
        jsonText = lines.sublist(1, lines.length - 1).join('\n');
      } else if (lines.first.startsWith('```')) {
        jsonText = lines.sublist(1, lines.length - 1).join('\n');
      }
    }
    
    final List<dynamic> decodedList = jsonDecode(jsonText) as List<dynamic>;
    final questions = <ExamQuestion>[];
    final uuid = const Uuid();

    for (final qMap in decodedList) {
      final map = qMap as Map<String, dynamic>;
      questions.add(ExamQuestion(
        questionId: uuid.v4(),
        type: map['type'] as String? ?? 'ShortAnswer',
        questionText: map['questionText'] as String? ?? '',
        options: map['options'] != null ? List<String>.from(map['options'] as List) : null,
        correctAnswer: map['correctAnswer'] as String? ?? '',
      ));
    }

    return PracticeExam(
      examId: uuid.v4(),
      deckId: deckId,
      questions: questions,
      timeLimitMinutes: timeLimitMinutes,
      generatedAt: DateTime.now(),
    );
  }

  Future<Map<String, String>> gradeShortAnswer(String questionText, String correctAnswer, String userAnswer) async {
    final systemPrompt = '''
You are an expert exam grader. Compare the user's short answer response to the model correct answer.
Grade the answer semantic accuracy as either "Correct", "Incorrect", or "Partial".
Provide a concise, 1-sentence feedback explanation.

Return ONLY a valid JSON object of this format with no other text:
{
  "aiGrade": "Correct",
  "aiFeedback": "Clear explanation with accurate terms."
}
''';

    final userMessage = '''
Question: $questionText
Model Correct Answer: $correctAnswer
User's Answer: $userAnswer
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
      return {
        'aiGrade': decoded['aiGrade'] as String? ?? 'Incorrect',
        'aiFeedback': decoded['aiFeedback'] as String? ?? '',
      };
    } catch (e) {
      return {
        'aiGrade': 'Incorrect',
        'aiFeedback': 'Error during automated grading: ${e.toString()}',
      };
    }
  }

  Future<ExamResult> generateExamReport(PracticeExam exam) async {
    // 1. Grade auto-gradable questions, and count stats
    int totalQuestions = exam.questions.length;
    int correctCount = 0;
    int mcCount = 0;
    int mcCorrect = 0;
    int tfCount = 0;
    int tfCorrect = 0;
    int saCount = 0;
    int saCorrect = 0;

    final questionDetails = <String>[];

    for (int i = 0; i < totalQuestions; i++) {
      final q = exam.questions[i];
      final uAns = q.userAnswer?.trim() ?? '';
      
      if (q.type == 'MC') {
        mcCount++;
        final isCorrect = uAns.toLowerCase() == q.correctAnswer.trim().toLowerCase();
        q.aiGrade = isCorrect ? 'Correct' : 'Incorrect';
        q.aiFeedback = isCorrect ? 'Correct selection.' : 'Incorrect. Correct answer: ${q.correctAnswer}';
        if (isCorrect) {
          correctCount++;
          mcCorrect++;
        }
      } else if (q.type == 'TF') {
        tfCount++;
        final isCorrect = uAns.toLowerCase() == q.correctAnswer.trim().toLowerCase();
        q.aiGrade = isCorrect ? 'Correct' : 'Incorrect';
        q.aiFeedback = isCorrect ? 'Correct choice.' : 'Incorrect. Correct statement was: ${q.correctAnswer}';
        if (isCorrect) {
          correctCount++;
          tfCorrect++;
        }
      } else {
        saCount++;
        // Grade ShortAnswer using LLM
        final grading = await gradeShortAnswer(q.questionText, q.correctAnswer, uAns);
        q.aiGrade = grading['aiGrade'];
        q.aiFeedback = grading['aiFeedback'];
        if (q.aiGrade == 'Correct') {
          correctCount++;
          saCorrect++;
        } else if (q.aiGrade == 'Partial') {
          correctCount++; // Treat partial as half-point or similar for final calculation
          saCorrect++;
        }
      }

      questionDetails.add(
        'Question ${i + 1} (${q.type}): ${q.questionText}\n'
        'Correct Answer: ${q.correctAnswer}\n'
        'User Answer: ${q.userAnswer}\n'
        'AI Grade: ${q.aiGrade}\n'
        'AI Feedback: ${q.aiFeedback}'
      );
    }

    final double score = totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;
    final byType = {
      if (mcCount > 0) 'Multiple Choice': '$mcCorrect/$mcCount',
      if (tfCount > 0) 'True/False': '$tfCorrect/$tfCount',
      if (saCount > 0) 'Short Answer': '$saCorrect/$saCount',
    };

    final systemPrompt = '''
You are an expert tutor writing a student exam evaluation report.
Analyze the user's exam performance and return a structured JSON feedback summary.
Include overall encouraging yet constructive feedback, and a list of specific weak topics they should study based on their errors.

Return ONLY a valid JSON object of this format with no other text:
{
  "aiFeedback": "Feedback summary here...",
  "weakTopics": ["Topic Name A", "Topic Name B"]
}
''';

    final userMessage = '''
Exam Score: ${score.toStringAsFixed(1)}%
Details:
${questionDetails.join('\n\n')}
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
      return ExamResult(
        score: score,
        byType: byType,
        aiFeedback: decoded['aiFeedback'] as String? ?? 'Exam completed successfully.',
        weakTopics: decoded['weakTopics'] != null ? List<String>.from(decoded['weakTopics'] as List) : [],
      );
    } catch (e) {
      return ExamResult(
        score: score,
        byType: byType,
        aiFeedback: 'Practice exam grading finished. You scored ${score.toStringAsFixed(1)}%.',
        weakTopics: ['Review missed questions for details.'],
      );
    }
  }
}
