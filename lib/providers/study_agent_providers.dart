import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/study_agent_service.dart';
import 'ai_providers.dart';
import '../models/study_session_plan.dart';

final studyAgentServiceProvider = Provider<StudyAgentService>((ref) {
  final aiService = ref.watch(dynamicAiServiceProvider);
  return StudyAgentService(aiService: aiService);
});

// A state notifier to hold the active agentic session plan
class ActiveSessionPlanNotifier extends StateNotifier<StudySessionPlan?> {
  ActiveSessionPlanNotifier() : super(null);

  void setPlan(StudySessionPlan plan) {
    state = plan;
  }

  void updatePlan(StudySessionPlan updatedPlan) {
    state = updatedPlan;
  }

  void clear() {
    state = null;
  }
}

final activeSessionPlanProvider = StateNotifierProvider<ActiveSessionPlanNotifier, StudySessionPlan?>((ref) {
  return ActiveSessionPlanNotifier();
});
