import 'dart:math';
import 'package:recall_app/models/scheduler_state.dart';
import 'package:recall_app/models/review_log.dart';

/// FSRS Rating values
enum Rating { again, hard, good, easy }

/// Scheduling result for a single rating
class SchedulingResult {
  final SchedulerState state;
  final ReviewLog log;
  SchedulingResult({required this.state, required this.log});
}

/// All 4 possible outcomes from a review
class SchedulingCards {
  final SchedulingResult again;
  final SchedulingResult hard;
  final SchedulingResult good;
  final SchedulingResult easy;

  SchedulingCards({
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });
}

class FSRSEngine {
  // Default FSRS v5 parameters (19 weights)
  static const List<double> defaultParameters = [
    0.4072, 1.1829, 3.1262, 15.4722, // w0-w3: initial stability for each rating
    7.2102, 0.5316, 1.0651, 0.0589, // w4-w7: difficulty
    1.5330, 0.1418, 1.0060, // w8-w10: stability after success
    1.9395, 0.1100, // w11-w12: stability after failure
    0.0000, 0.0000, // w13-w14: (reserved)
    0.0000, 2.9898, 0.5100, 0.6700 // w15-w18: short-term
  ];

  double targetRetention; // default 0.9
  List<double> parameters;

  FSRSEngine({
    this.targetRetention = 0.9,
    List<double>? parameters,
  }) : parameters = parameters ?? List.from(defaultParameters);

  SchedulingCards repeat(SchedulerState state, DateTime now) {
    return SchedulingCards(
      again: _evaluateNextState(state, Rating.again, now),
      hard: _evaluateNextState(state, Rating.hard, now),
      good: _evaluateNextState(state, Rating.good, now),
      easy: _evaluateNextState(state, Rating.easy, now),
    );
  }

  SchedulingResult _evaluateNextState(SchedulerState state, Rating rating, DateTime now) {
    double nextStability = 0.0;
    double nextDifficulty = 0.0;
    int nextInterval = 0;
    CardState nextCardState = state.state;
    double elapsedDays = state.lastReview != null
        ? now.difference(state.lastReview!).inMilliseconds / 86400000.0
        : 0.0;

    elapsedDays = max(0.0, elapsedDays);

    if (state.state == CardState.newCard) {
      nextDifficulty = _initDifficulty(rating);
      nextStability = _initStability(rating);
      
      if (rating == Rating.easy) {
        nextCardState = CardState.review;
        nextInterval = _nextInterval(nextStability).round();
      } else if (rating == Rating.good) {
        nextCardState = CardState.learning;
        nextInterval = _nextInterval(nextStability).round();
      } else {
        nextCardState = CardState.learning;
        nextInterval = 0; // due now
      }
    } else if (state.state == CardState.learning || state.state == CardState.relearning) {
      nextDifficulty = _nextDifficulty(state.difficulty, rating);
      nextStability = state.stability; // keep current or recalculate based on logic
      
      if (rating == Rating.again) {
        nextCardState = state.state;
        nextInterval = 0;
      } else if (rating == Rating.hard) {
        nextCardState = state.state;
        nextInterval = 0;
      } else {
        nextCardState = CardState.review;
        nextInterval = _nextInterval(nextStability).round();
      }
    } else { // CardState.review
      double retrievability = _forgettingCurve(elapsedDays, state.stability);
      nextDifficulty = _nextDifficulty(state.difficulty, rating);

      if (rating == Rating.again) {
        nextCardState = CardState.relearning;
        nextStability = _nextForgetStability(state.difficulty, state.stability, retrievability);
        nextInterval = 0;
      } else {
        nextCardState = CardState.review;
        nextStability = _nextRecallStability(state.difficulty, state.stability, retrievability, rating);
        nextInterval = _nextInterval(nextStability).round();
      }
    }

    nextStability = max(0.01, nextStability);
    if (nextCardState == CardState.review) {
      nextInterval = max(1, nextInterval);
    } else {
      nextInterval = max(0, nextInterval);
    }

    int nextReps = state.reps + 1;
    int nextLapses = state.lapses + (rating == Rating.again ? 1 : 0);

    SchedulerState newState = SchedulerState(
      cardId: state.cardId,
      stability: nextStability,
      difficulty: nextDifficulty,
      dueDate: now.add(Duration(days: nextInterval)),
      reps: nextReps,
      lapses: nextLapses,
      lastReview: now,
      state: nextCardState,
    );

    ReviewLog log = ReviewLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_${rating.index}',
      cardId: state.cardId,
      rating: rating.index + 1, // 1=again, 2=hard, 3=good, 4=easy
      reviewTimeMs: 0,
      elapsedDays: elapsedDays,
      scheduledDays: nextInterval.toDouble(),
      reviewedAt: now,
    );

    return SchedulingResult(state: newState, log: log);
  }

  double _initDifficulty(Rating rating) {
    int r = rating.index + 1;
    double d = parameters[4] - exp(parameters[5] * (r - 1)) + 1;
    return max(1.0, min(10.0, d));
  }

  double _initStability(Rating rating) {
    return max(0.01, parameters[rating.index]);
  }

  double _nextDifficulty(double d, Rating rating) {
    int r = rating.index + 1;
    double d0_3 = parameters[4] - exp(parameters[5] * (3 - 1)) + 1;
    double nextD = parameters[7] * d0_3 + (1 - parameters[7]) * (d - parameters[6] * (r - 3));
    return max(1.0, min(10.0, nextD));
  }

  double _nextRecallStability(double d, double s, double r, Rating rating) {
    double hardPenalty = rating == Rating.hard ? parameters[15] : 1.0;
    double easyBonus = rating == Rating.easy ? parameters[16] : 1.0;
    
    double nextS = s * (1 + exp(parameters[8]) * 
      (11 - d) * 
      pow(s, -parameters[9]) * 
      (exp(parameters[10] * (1 - r)) - 1) * 
      hardPenalty * easyBonus);
    return nextS;
  }

  double _nextForgetStability(double d, double s, double r) {
    return parameters[11] * 
      pow(d, -parameters[12]) * 
      (pow(s + 1, parameters[13]) - 1) * 
      exp(parameters[14] * (1 - r));
  }

  double _nextInterval(double stability) {
    return stability * (1 / targetRetention - 1) * 9.0;
  }

  double _forgettingCurve(double elapsedDays, double stability) {
    if (stability <= 0.0) return 0.0;
    return pow(1.0 + elapsedDays / (9.0 * stability), -1.0).toDouble();
  }
}
