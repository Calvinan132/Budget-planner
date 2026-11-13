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
  startDay: number; // Ngày bắt đầu tính kế hoạch (1 = đầu tháng, >1 = giữa tháng)
  activeDays: number; // Số ngày tính kế hoạch (từ startDay đến cuối tháng)
  initialBudget: number; // Số tiền người dùng nhập đầu tháng có thể sử dụng
  totalPlanned: number; // Tổng số tiền tiêu dự kiến (tính theo activeDays)
  actualSpent: number; // Tổng chi tiêu thực tế
  savedAmount: number; // Tiền tiết kiệm (Heo đất)
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
  month: z.number().min(1).max(12).optional(),
  year: z.number().min(2000).max(2100).optional(),
  startDay: z.number().min(1).max(31).optional(), // Ngày bắt đầu tính (client tự tính số ngày còn lại)
  activeDays: z.number().min(1).max(31).optional(), // Số ngày tính kế hoạch (client gửi lên)
  initialBudget: z.number().min(0, 'Initial budget must be non-negative').optional(),
  totalPlanned: z.number().min(0).optional(), // Client có thể gửi totalPlanned đã tính sẵn
  dailyRoutines: z.array(dailyRoutineSchema).default([]),
  weeklyRoutines: z.array(weeklyRoutineSchema).default([]),
  monthlyFixed: z.array(monthlyFixedSchema).default([]),
});

export const updatePlanSchema = z.object({
  month: z.number().min(1).max(12).optional(),
  year: z.number().min(2000).max(2100).optional(),
  startDay: z.number().min(1).max(31).optional(),
  activeDays: z.number().min(1).max(31).optional(),
  initialBudget: z.number().min(0, 'Initial budget must be non-negative').optional(),
  totalPlanned: z.number().min(0).optional(), // Client có thể gửi totalPlanned đã tính sẵn
  dailyRoutines: z.array(dailyRoutineSchema).optional(),
  weeklyRoutines: z.array(weeklyRoutineSchema).optional(),
  monthlyFixed: z.array(monthlyFixedSchema).optional(),
  isLocked: z.boolean().optional(),
});

export type CreatePlanDTO = z.infer<typeof createPlanSchema>;
export type UpdatePlanDTO = z.infer<typeof updatePlanSchema>;
