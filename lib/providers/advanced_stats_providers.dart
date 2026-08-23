import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stats_service.dart';

final statsServiceProvider = Provider<StatsService>((ref) => StatsService());

final retentionCurveProvider = FutureProvider.family<List<({double days, double retention})>, String>((ref, deckId) {
  final service = ref.watch(statsServiceProvider);
  return service.getRetentionCurve(deckId);
});

final reviewForecastProvider = FutureProvider.family<List<({DateTime date, int count})>, String>((ref, deckId) {
  final service = ref.watch(statsServiceProvider);
  return service.getReviewForecast(deckId);
});

final heatmapDataProvider = FutureProvider<Map<DateTime, int>>((ref) {
  final service = ref.watch(statsServiceProvider);
  return service.getHeatmapData();
});
