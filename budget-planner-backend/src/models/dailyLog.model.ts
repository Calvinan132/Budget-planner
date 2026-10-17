import { z } from 'zod';

export type ItemType = 'daily' | 'weekly';
export type ItemStatus = 'pending' | 'completed' | 'skipped';

export interface DailyCheckInItem {
  id: string;
  routineId: string;
  name: string;
  amount: number;
  type: ItemType;
  status: ItemStatus;
}

export interface UnexpectedExpense {
  id: string;
  amount: number;
  reason: string;
  createdAt: string;
}

export interface DailyLog {
  id: string; // userUid_YYYY_MM_DD
  userId: string;
  date: string; // YYYY-MM-DD
  items: DailyCheckInItem[];
  unexpectedExpenses: UnexpectedExpense[];
  createdAt: string;
  updatedAt: string;
}

export const checkInStatusSchema = z.object({
  itemId: z.string().min(1, 'Item ID is required'),
  status: z.enum(['completed', 'skipped'], {
    errorMap: () => ({ message: "Status must be 'completed' or 'skipped'" }),
  }),
});

export const unexpectedExpenseSchema = z.object({
  amount: z.number().positive('Amount must be greater than 0'),
  reason: z.string().min(1, 'Reason for unexpected expense is required'),
});

export type CheckInStatusDTO = z.infer<typeof checkInStatusSchema>;
export type UnexpectedExpenseDTO = z.infer<typeof unexpectedExpenseSchema>;
