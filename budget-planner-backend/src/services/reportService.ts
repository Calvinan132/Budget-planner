import { DateTime } from 'luxon';
import { DailyBreakdownHistoryResponse, MonthlyReportResponse, SkippedItemInsight } from '../models/report.model';
import { MonthlyPlan } from '../models/plan.model';
import { DailyLog } from '../models/dailyLog.model';
import { PlanService } from './planService';
import { inMemoryDb } from '../config/inMemoryDb';

export class ReportService {
  public static async getMonthlyReport(
    userId: string,
    month?: number,
    year?: number
  ): Promise<MonthlyReportResponse> {
    const nowVietnam = DateTime.now().setZone('Asia/Ho_Chi_Minh');
    const targetMonth = month || nowVietnam.month;
    const targetYear = year || nowVietnam.year;
    const monthStr = targetMonth.toString().padStart(2, '0');

    const planDocId = PlanService.getPlanDocId(userId, targetYear, targetMonth);
    const plan = inMemoryDb.plans[planDocId] as MonthlyPlan | undefined;

    let totalPlanned = 0;
    let actualSpent = 0;
    let savedAmount = 0;

    if (plan) {
      totalPlanned = plan.totalPlanned;
      actualSpent = plan.actualSpent;
      savedAmount = plan.savedAmount;
    }

    const startDate = `${targetYear}-${monthStr}-01`;
    const daysInMonth = new Date(targetYear, targetMonth, 0).getDate();
    const endDate = `${targetYear}-${monthStr}-${daysInMonth.toString().padStart(2, '0')}`;

    const skippedMap: Map<string, { count: number; saved: number }> = new Map();
    const allUnexpectedExpenses: { id: string; date: string; amount: number; reason: string }[] = [];

    const logs = Object.values(inMemoryDb.dailyLogs).filter(
      (log: any) => log.userId === userId && log.date >= startDate && log.date <= endDate
    ) as DailyLog[];

    logs.forEach((log) => {
      log.items.forEach((item) => {
        if (item.status === 'skipped') {
          const existing = skippedMap.get(item.name) || { count: 0, saved: 0 };
          skippedMap.set(item.name, {
            count: existing.count + 1,
            saved: existing.saved + item.amount,
          });
        }
      });

      if (log.unexpectedExpenses && Array.isArray(log.unexpectedExpenses)) {
        log.unexpectedExpenses.forEach((exp) => {
          allUnexpectedExpenses.push({
            id: exp.id,
            date: log.date,
            amount: exp.amount,
            reason: exp.reason,
          });
        });
      }
    });

    const skippedItemsInsights: SkippedItemInsight[] = Array.from(skippedMap.entries())
      .map(([name, val]) => ({
        name,
        skippedCount: val.count,
        totalSavedAmount: Math.round(val.saved * 100) / 100,
      }))
      .sort((a, b) => b.skippedCount - a.skippedCount);

    const topUnexpectedExpenses = allUnexpectedExpenses
      .sort((a, b) => b.amount - a.amount)
      .slice(0, 10);

    return {
      month: targetMonth,
      year: targetYear,
      totalPlanned,
      actualSpent,
      savedAmount,
      skippedItemsInsights,
      topUnexpectedExpenses,
    };
  }

  public static async getDailyHistory(
    userId: string,
    month?: number,
    year?: number
  ): Promise<DailyBreakdownHistoryResponse> {
    const nowVietnam = DateTime.now().setZone('Asia/Ho_Chi_Minh');
    const targetMonth = month || nowVietnam.month;
    const targetYear = year || nowVietnam.year;
    const monthStr = targetMonth.toString().padStart(2, '0');

    const startDate = `${targetYear}-${monthStr}-01`;
    const daysInMonth = new Date(targetYear, targetMonth, 0).getDate();
    const endDate = `${targetYear}-${monthStr}-${daysInMonth.toString().padStart(2, '0')}`;

    const logs = (Object.values(inMemoryDb.dailyLogs).filter(
      (log: any) => log.userId === userId && log.date >= startDate && log.date <= endDate
    ) as DailyLog[]).sort((a, b) => a.date.localeCompare(b.date));

    return {
      month: targetMonth,
      year: targetYear,
      daysCount: logs.length,
      logs,
    };
  }
}
