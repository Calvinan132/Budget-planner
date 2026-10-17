import { z } from 'zod';

export interface DailyRoutine {
  id: string;
  name: string;
  amount: number;
}

export interface WeeklyRoutine {
  id: string;
  name: string;
  amount: number;
  frequencyPerWeek: number;
}

export interface MonthlyFixed {
  id: string;
  name: string;
  amount: number;
}

export interface MonthlyPlan {
  id: string; // userUid_YYYY_MM
  userId: string;
  month: number; // 1-12
  year: number;
  totalPlanned: number;
  actualSpent: number;
  savedAmount: number;
  isLocked: boolean;
  dailyRoutines: DailyRoutine[];
  weeklyRoutines: WeeklyRoutine[];
  monthlyFixed: MonthlyFixed[];
  createdAt: string;
  updatedAt: string;
}

const dailyRoutineSchema = z.object({
  id: z.string().optional(),
  name: z.string().min(1, 'Routine name is required'),
  amount: z.number().min(0, 'Amount must be non-negative'),
});

const weeklyRoutineSchema = z.object({
  id: z.string().optional(),
  name: z.string().min(1, 'Routine name is required'),
  amount: z.number().min(0, 'Amount must be non-negative'),
  frequencyPerWeek: z.number().min(1, 'Frequency per week must be at least 1').max(7, 'Frequency per week cannot exceed 7'),
});

const monthlyFixedSchema = z.object({
  id: z.string().optional(),
  name: z.string().min(1, 'Expense name is required'),
  amount: z.number().min(0, 'Amount must be non-negative'),
});

export const createPlanSchema = z.object({
  month: z.number().min(1).max(12),
  year: z.number().min(2000).max(2100),
  dailyRoutines: z.array(dailyRoutineSchema).default([]),
  weeklyRoutines: z.array(weeklyRoutineSchema).default([]),
  monthlyFixed: z.array(monthlyFixedSchema).default([]),
});

export const updatePlanSchema = z.object({
  month: z.number().min(1).max(12).optional(),
  year: z.number().min(2000).max(2100).optional(),
  dailyRoutines: z.array(dailyRoutineSchema).optional(),
  weeklyRoutines: z.array(weeklyRoutineSchema).optional(),
  monthlyFixed: z.array(monthlyFixedSchema).optional(),
  isLocked: z.boolean().optional(),
});

export type CreatePlanDTO = z.infer<typeof createPlanSchema>;
export type UpdatePlanDTO = z.infer<typeof updatePlanSchema>;
