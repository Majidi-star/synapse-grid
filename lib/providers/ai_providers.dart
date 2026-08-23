import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import '../services/ai_card_generator.dart';
import '../services/pdf_service.dart';
import '../models/ai_provider.dart';
import '../models/ai_generation_queue.dart';

final dynamicAiServiceProvider = Provider<DynamicAiService>((ref) => DynamicAiService());

final aiCardGeneratorProvider = Provider<AiCardGenerator>((ref) {
  final aiService = ref.watch(dynamicAiServiceProvider);
  return AiCardGenerator(aiService: aiService);
});

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());

final activeAiProvider = FutureProvider<AiProvider?>((ref) {
  final service = ref.watch(dynamicAiServiceProvider);
  return service.getActiveProvider();
});

final aiProvidersListProvider = FutureProvider<List<AiProvider>>((ref) {
  final service = ref.watch(dynamicAiServiceProvider);
  return service.getAllProviders();
});

final aiPendingQueueProvider = FutureProvider.family<List<AiGeneratedCard>, String>((ref, deckId) {
  final generator = ref.watch(aiCardGeneratorProvider);
  return generator.getPendingQueue(deckId);
});
