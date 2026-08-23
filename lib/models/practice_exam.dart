import 'dart:convert';

class PracticeExam {
  final String examId;
  final String deckId;
  final List<ExamQuestion> questions;
  final int timeLimitMinutes;
  final DateTime generatedAt;
  
  PracticeExam({
    required this.examId,
    required this.deckId,
    required this.questions,
    required this.timeLimitMinutes,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'deckId': deckId,
      'timeLimitMinutes': timeLimitMinutes,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

class ExamQuestion {
  final String questionId;
  final String type; // 'MC' | 'TF' | 'ShortAnswer'
  final String questionText;
  final List<String>? options;
  final String correctAnswer;
  String? userAnswer;
  String? aiGrade; // 'Correct' | 'Incorrect' | 'Partial'
  String? aiFeedback;
  
  ExamQuestion({
    required this.questionId,
    required this.type,
    required this.questionText,
    this.options,
    required this.correctAnswer,
    this.userAnswer,
    this.aiGrade,
    this.aiFeedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'type': type,
      'questionText': questionText,
      'options': options != null ? jsonEncode(options) : null,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      'aiGrade': aiGrade,
      'aiFeedback': aiFeedback,
    };
  }

  factory ExamQuestion.fromMap(Map<String, dynamic> map) {
    return ExamQuestion(
      questionId: map['questionId'] as String,
      type: map['type'] as String,
      questionText: map['questionText'] as String,
      options: map['options'] != null ? List<String>.from(jsonDecode(map['options'] as String) as List) : null,
      correctAnswer: map['correctAnswer'] as String,
      userAnswer: map['userAnswer'] as String?,
      aiGrade: map['aiGrade'] as String?,
      aiFeedback: map['aiFeedback'] as String?,
    );
  }
}

class ExamResult {
  final double score; // Percentage e.g. 85.0
  final Map<String, dynamic> byType; // e.g. {'MC': '4/5', 'TF': '2/2'}
  final String aiFeedback;
  final List<String> weakTopics;

  ExamResult({
    required this.score,
    required this.byType,
    required this.aiFeedback,
    required this.weakTopics,
  });

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'byType': jsonEncode(byType),
      'aiFeedback': aiFeedback,
      'weakTopics': jsonEncode(weakTopics),
    };
  }
}
