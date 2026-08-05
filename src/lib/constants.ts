export const CardType = {
  BASIC: 'BASIC',
  CLOZE: 'CLOZE',
  IMAGE_OCCLUSION: 'IMAGE_OCCLUSION',
  MULTIPLE_CHOICE: 'MULTIPLE_CHOICE',
  TYPED_ANSWER: 'TYPED_ANSWER',
} as const;

export type CardType = (typeof CardType)[keyof typeof CardType];

export const State = {
  NEW: 'NEW',
  LEARNING: 'LEARNING',
  REVIEW: 'REVIEW',
  RELEARNING: 'RELEARNING',
} as const;

export type State = (typeof State)[keyof typeof State];

export const Rating = {
  AGAIN: 'AGAIN',
  HARD: 'HARD',
  GOOD: 'GOOD',
  EASY: 'EASY',
} as const;

export type Rating = (typeof Rating)[keyof typeof Rating];

export const JobStatus = {
  PENDING: 'PENDING',
  PROCESSING: 'PROCESSING',
  COMPLETED: 'COMPLETED',
  FAILED: 'FAILED',
} as const;

export type JobStatus = (typeof JobStatus)[keyof typeof JobStatus];
