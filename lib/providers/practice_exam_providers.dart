import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/practice_exam_service.dart';
import 'ai_providers.dart';

final practiceExamServiceProvider = Provider<PracticeExamService>((ref) {
  final aiService = ref.watch(dynamicAiServiceProvider);
  return PracticeExamService(aiService: aiService);
});
