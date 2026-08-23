import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/scheduler_state.dart';
import 'package:recall_app/providers/review_providers.dart';

final masteryBreakdownProvider = FutureProvider.family<Map<CardState, int>, String>((ref, deckId) async {
  final service = ref.watch(reviewServiceProvider);
  return service.getMasteryBreakdown(deckId);
});

final streakProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(reviewServiceProvider);
  return service.getStreak();
});

final averageSpeedProvider = FutureProvider.family<double, String>((ref, deckId) async {
  final service = ref.watch(reviewServiceProvider);
  return service.getAverageSpeed(deckId);
});

final retentionRateProvider = FutureProvider.family<double, String>((ref, deckId) async {
  final service = ref.watch(reviewServiceProvider);
  return service.getRetentionRate(deckId);
});

final weeklyActivityProvider = FutureProvider<List<int>>((ref) async {
  final service = ref.watch(reviewServiceProvider);
  return service.getWeeklyActivity();
});
