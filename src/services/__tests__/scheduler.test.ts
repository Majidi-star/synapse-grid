import { describe, it, expect, vi, beforeEach } from 'vitest';
import { SchedulerService } from '../scheduler';
import { Rating as PrismaRating, State as PrismaState, PrismaClient } from '@prisma/client';

// Mock PrismaClient
vi.mock('@prisma/client', () => {
  const mPrismaClient = {
    card: {
      findMany: vi.fn(),
    },
    cardScheduleState: {
      findUnique: vi.fn(),
      findMany: vi.fn(),
    },
    $transaction: vi.fn(),
  };
  return {
    PrismaClient: vi.fn(() => mPrismaClient),
    Rating: { AGAIN: 'AGAIN', HARD: 'HARD', GOOD: 'GOOD', EASY: 'EASY' },
    State: { NEW: 'NEW', LEARNING: 'LEARNING', REVIEW: 'REVIEW', RELEARNING: 'RELEARNING' }
  };
});

describe('SchedulerService', () => {
  const prismaMock = new PrismaClient() as any;

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getDueCards', () => {
    it('should return due cards for a user', async () => {
      const mockCards = [
        { id: '1', front: 'Q1' },
        { id: '2', front: 'Q2' }
      ];
      prismaMock.card.findMany.mockResolvedValue(mockCards);

      const cards = await SchedulerService.getDueCards('user-1', 10);
      expect(prismaMock.card.findMany).toHaveBeenCalled();
      expect(cards).toEqual(mockCards);
    });
  });

  describe('recordReview', () => {
    it('should create schedule and log for a new card', async () => {
      // Simulate no existing state (new card)
      prismaMock.cardScheduleState.findUnique.mockResolvedValue(null);
      
      await SchedulerService.recordReview('card-1', 'user-1', PrismaRating.GOOD);

      expect(prismaMock.cardScheduleState.findUnique).toHaveBeenCalledWith({
        where: { cardId: 'card-1' }
      });
      
      expect(prismaMock.$transaction).toHaveBeenCalled();
      const transactionCalls = prismaMock.$transaction.mock.calls[0][0];
      expect(transactionCalls.length).toBe(2);
    });

    it('should update schedule and log for an existing card', async () => {
      // Simulate existing state
      const existingState = {
        cardId: 'card-2',
        due: new Date(),
        stability: 1,
        difficulty: 5,
        elapsedDays: 0,
        scheduledDays: 1,
        reps: 1,
        lapses: 0,
        state: PrismaState.LEARNING,
        lastReview: new Date()
      };
      
      prismaMock.cardScheduleState.findUnique.mockResolvedValue(existingState);
      
      await SchedulerService.recordReview('card-2', 'user-1', PrismaRating.EASY);

      expect(prismaMock.cardScheduleState.findUnique).toHaveBeenCalledWith({
        where: { cardId: 'card-2' }
      });
      
      expect(prismaMock.$transaction).toHaveBeenCalled();
    });
  });

  describe('getForecast', () => {
    it('should return a 7-day forecast array', async () => {
      const today = new Date();
      const mockStates = [
        { due: today },
        { due: today }
      ];
      prismaMock.cardScheduleState.findMany.mockResolvedValue(mockStates);

      const forecast = await SchedulerService.getForecast('user-1', 7);
      
      expect(prismaMock.cardScheduleState.findMany).toHaveBeenCalled();
      expect(forecast.length).toBe(7);
      
      const todayString = today.toISOString().split('T')[0];
      const todayForecast = forecast.find(f => f.date === todayString);
      expect(todayForecast?.count).toBe(2);
    });
  });
});
