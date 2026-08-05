import { PrismaClient, Rating as PrismaRating, State as PrismaState } from '@prisma/client';
import { fsrs, Rating, State, Card as FSRSCard, FSRSParameters } from 'ts-fsrs';

const prisma = new PrismaClient();

// The FSRS algorithm instance with default parameters.
// The user's retention target preference can be applied to these parameters later.
const f = fsrs();

export class SchedulerService {
  /**
   * Helper to convert Prisma State enum to FSRS State enum.
   */
  private static mapPrismaStateToFSRS(state: PrismaState): State {
    switch (state) {
      case PrismaState.NEW: return State.New;
      case PrismaState.LEARNING: return State.Learning;
      case PrismaState.REVIEW: return State.Review;
      case PrismaState.RELEARNING: return State.Relearning;
      default: return State.New;
    }
  }

  /**
   * Helper to convert FSRS State enum to Prisma State enum.
   */
  private static mapFSRSStateToPrisma(state: State): PrismaState {
    switch (state) {
      case State.New: return PrismaState.NEW;
      case State.Learning: return PrismaState.LEARNING;
      case State.Review: return PrismaState.REVIEW;
      case State.Relearning: return PrismaState.RELEARNING;
      default: return PrismaState.NEW;
    }
  }

  /**
   * Helper to convert Prisma Rating enum to FSRS Rating enum.
   */
  private static mapPrismaRatingToFSRS(rating: PrismaRating): Rating {
    switch (rating) {
      case PrismaRating.AGAIN: return Rating.Again;
      case PrismaRating.HARD: return Rating.Hard;
      case PrismaRating.GOOD: return Rating.Good;
      case PrismaRating.EASY: return Rating.Easy;
      default: return Rating.Again;
    }
  }

  /**
   * Fetch cards that are due for review for a given user.
   */
  static async getDueCards(userId: string, limit = 50, deckId?: string) {
    const now = new Date();

    const whereClause: any = {
      deck: {
        userId: userId,
        ...(deckId ? { id: deckId } : {})
      },
      scheduleState: {
        due: { lte: now }
      }
    };

    const cards = await prisma.card.findMany({
      where: whereClause,
      include: {
        scheduleState: true
      },
      orderBy: {
        scheduleState: {
          due: 'asc'
        }
      },
      take: limit,
    });

    // TODO: Implement advanced sibling burying logic if required.
    // For now, we return all due cards.
    return cards;
  }

  /**
   * Record a review for a card, computing the next FSRS state.
   */
  static async recordReview(cardId: string, userId: string, rating: PrismaRating) {
    const cardState = await prisma.cardScheduleState.findUnique({
      where: { cardId }
    });

    const now = new Date();

    let currentFSRSCard: FSRSCard;

    if (!cardState) {
      // First time review, create an empty card
      currentFSRSCard = fsrs().createEmptyCard();
    } else {
      currentFSRSCard = {
        due: cardState.due,
        stability: cardState.stability,
        difficulty: cardState.difficulty,
        elapsed_days: cardState.elapsedDays,
        scheduled_days: cardState.scheduledDays,
        reps: cardState.reps,
        lapses: cardState.lapses,
        state: this.mapPrismaStateToFSRS(cardState.state),
        last_review: cardState.lastReview || undefined,
      };
    }

    const fsrsRating = this.mapPrismaRatingToFSRS(rating);
    
    // Calculate the next state using the FSRS repeat function
    const schedulingInfo = f.repeat(currentFSRSCard, now);
    const nextLog = schedulingInfo[fsrsRating];

    const nextCard = nextLog.card;
    const reviewLog = nextLog.log;

    // Transaction to update both the current state and record the review log
    await prisma.$transaction([
      prisma.cardScheduleState.upsert({
        where: { cardId },
        update: {
          due: nextCard.due,
          stability: nextCard.stability,
          difficulty: nextCard.difficulty,
          elapsedDays: nextCard.elapsed_days,
          scheduledDays: nextCard.scheduled_days,
          reps: nextCard.reps,
          lapses: nextCard.lapses,
          state: this.mapFSRSStateToPrisma(nextCard.state),
          lastReview: nextCard.last_review,
        },
        create: {
          cardId,
          due: nextCard.due,
          stability: nextCard.stability,
          difficulty: nextCard.difficulty,
          elapsedDays: nextCard.elapsed_days,
          scheduledDays: nextCard.scheduled_days,
          reps: nextCard.reps,
          lapses: nextCard.lapses,
          state: this.mapFSRSStateToPrisma(nextCard.state),
          lastReview: nextCard.last_review,
        }
      }),
      prisma.reviewLog.create({
        data: {
          cardId,
          userId,
          reviewedAt: now,
          rating: rating,
          scheduledDays: reviewLog.scheduled_days,
          elapsedDays: reviewLog.elapsed_days,
          state: this.mapFSRSStateToPrisma(reviewLog.state),
        }
      })
    ]);
  }

  /**
   * Return a summary forecast of upcoming due cards for the next X days.
   */
  static async getForecast(userId: string, days: number = 7) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const endDate = new Date(today);
    endDate.setDate(endDate.getDate() + days);

    const states = await prisma.cardScheduleState.findMany({
      where: {
        card: {
          deck: {
            userId: userId,
          }
        },
        due: {
          gte: today,
          lte: endDate,
        }
      },
      select: {
        due: true,
      }
    });

    const forecast: Record<string, number> = {};

    for (let i = 0; i < days; i++) {
      const targetDate = new Date(today);
      targetDate.setDate(targetDate.getDate() + i);
      const dateString = targetDate.toISOString().split('T')[0];
      forecast[dateString] = 0;
    }

    states.forEach(state => {
      const dateString = state.due.toISOString().split('T')[0];
      if (forecast[dateString] !== undefined) {
        forecast[dateString]++;
      }
    });

    return Object.entries(forecast)
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date));
  }
}
