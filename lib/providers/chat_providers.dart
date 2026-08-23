import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_tutor_service.dart';
import 'ai_providers.dart';
import '../models/chat_message.dart';

final aiTutorServiceProvider = Provider<AiTutorService>((ref) {
  final aiService = ref.watch(dynamicAiServiceProvider);
  return AiTutorService(aiService: aiService);
});

final chatHistoryProvider = FutureProvider.family<List<ChatMessage>, String>((ref, deckId) {
  final tutorService = ref.watch(aiTutorServiceProvider);
  return tutorService.getChatHistory(deckId);
});
