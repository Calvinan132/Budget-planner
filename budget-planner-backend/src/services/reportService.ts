import { DateTime } from 'luxon';
import { DailyBreakdownHistoryResponse, MonthlyReportResponse, SkippedItemInsight } from '../models/report.model';
import { MonthlyPlan } from '../models/plan.model';
import { DailyLog } from '../models/dailyLog.model';
import { PlanService } from './planService';
import { inMemoryDb } from '../config/inMemoryDb';
import { db } from '../config/firebase';

const PLANS_COLLECTION = 'monthly_plans';
const DAILY_LOGS_COLLECTION = 'daily_logs';

export class ReportService {
  /**
   * Lấy kế hoạch của một tháng từ Firestore (chính), fallback về inMemoryDb nếu lỗi mạng.
   */
  private static async getPlanDoc(planDocId: string): Promise<MonthlyPlan | undefined> {
    // ⚡ SHORT-CIRCUIT: inMemoryDb trước (tránh Firestore timeout)
    if (inMemoryDb.plans[planDocId]) {
      return inMemoryDb.plans[planDocId] as MonthlyPlan;
    }
    try {
      const docSnap = await db.collection(PLANS_COLLECTION).doc(planDocId).get();
      if (docSnap.exists) {
        const plan = docSnap.data() as MonthlyPlan;
        inMemoryDb.plans[planDocId] = plan;
        return plan;
      }
    } catch (err) {
      console.warn('[ReportService] Firestore getPlanDoc failed, fallback to inMemoryDb:', err);
    }
    return inMemoryDb.plans[planDocId] as MonthlyPlan | undefined;
  }

  /**
   * Lấy toàn bộ daily_logs của một khoảng ngày từ Firestore (chính).
   * Chỉ filter theo userId (dùng index tự động của Firestore) rồi lọc khoảng ngày trong bộ nhớ,
   * tránh yêu cầu composite index khi chưa deploy firestore.indexes.json.
   */
  private static async getLogsForUserInRange(
    userId: string,
    startDate: string,
    endDate: string
  ): Promise<DailyLog[]> {
    // ⚡ SHORT-CIRCUIT: Với dev_user_monitor, dùng inMemoryDb luôn
    if (userId === 'dev_user_monitor') {
      return Object.values(inMemoryDb.dailyLogs).filter(
        (log: any) => log.userId === userId && log.date >= startDate && log.date <= endDate
      ) as DailyLog[];
    }
    try {
      const snap = await db.collection(DAILY_LOGS_COLLECTION).where('userId', '==', userId).get();
      const logs = snap.docs
        .map((d) => d.data() as DailyLog)
        .filter((log) => log.date >= startDate && log.date <= endDate)
        .sort((a, b) => a.date.localeCompare(b.date));
      return logs;
    } catch (err) {
      console.warn('[ReportService] Firestore getLogsForUserInRange failed, fallback to inMemoryDb:', err);
      return Object.values(inMemoryDb.dailyLogs).filter(
        (log: any) => log.userId === userId && log.date >= startDate && log.date <= endDate
      ) as DailyLog[];
    }
  }

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

    // ⚡ Ensure dev_user_monitor plan is seeded in inMemoryDb before getPlanDoc
    if (userId === 'dev_user_monitor' && !inMemoryDb.plans[planDocId]) {
      try {
        await PlanService.getCurrentPlan(userId, targetMonth, targetYear);
      } catch (_) {}
    }

    const plan = await this.getPlanDoc(planDocId);

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

    const logs = await this.getLogsForUserInRange(userId, startDate, endDate);

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

    const logs = (await this.getLogsForUserInRange(userId, startDate, endDate)).sort((a, b) =>
      a.date.localeCompare(b.date)
    );

    return {
      month: targetMonth,
      year: targetYear,
      daysCount: logs.length,
      logs,
    };
  }
}
