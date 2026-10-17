import { z } from 'zod';
import { DailyLog } from './dailyLog.model';

export interface SkippedItemInsight {
  name: string;
  skippedCount: number;
  totalSavedAmount: number;
}

export interface MonthlyReportResponse {
  month: number;
  year: number;
  totalPlanned: number;
  actualSpent: number;
  savedAmount: number;
  skippedItemsInsights: SkippedItemInsight[];
  topUnexpectedExpenses: {
    id: string;
    date: string;
    amount: number;
    reason: string;
  }[];
}

export interface DailyBreakdownHistoryResponse {
  month: number;
  year: number;
  daysCount: number;
  logs: DailyLog[];
}

export const reportQuerySchema = z.object({
  month: z
    .string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : undefined))
    .refine((val) => val === undefined || (val >= 1 && val <= 12), {
      message: 'Month must be between 1 and 12',
    }),
  year: z
    .string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : undefined))
    .refine((val) => val === undefined || (val >= 2000 && val <= 2100), {
      message: 'Year must be a valid 4-digit year',
    }),
});

export type ReportQueryDTO = z.infer<typeof reportQuerySchema>;
