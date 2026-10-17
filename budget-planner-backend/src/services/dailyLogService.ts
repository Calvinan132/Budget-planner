import { v4 as uuidv4 } from 'uuid';
import { DateTime } from 'luxon';
import { CheckInStatusDTO, DailyCheckInItem, DailyLog, UnexpectedExpense, UnexpectedExpenseDTO } from '../models/dailyLog.model';
import { MonthlyPlan } from '../models/plan.model';
import { AppError } from '../middlewares/errorHandler';
import { HTTP_STATUS } from '../constants/statusCodes';
import { MESSAGES } from '../constants/messages';
import { PlanService } from './planService';
import { inMemoryDb } from '../config/inMemoryDb';

export class DailyLogService {
  public static getDailyLogDocId(userId: string, dateStr: string): string {
    const sanitizedDate = dateStr.replace(/-/g, '_');
    return `${userId}_${sanitizedDate}`;
  }

  public static async getTodayLog(userId: string, targetDate?: string): Promise<DailyLog> {
    const dateStr = targetDate || DateTime.now().setZone('Asia/Ho_Chi_Minh').toISODate()!;
    const docId = this.getDailyLogDocId(userId, dateStr);

    let log = inMemoryDb.dailyLogs[docId];

    if (log) {
      return log;
    }

    const dt = DateTime.fromISO(dateStr);
    const planDocId = PlanService.getPlanDocId(userId, dt.year, dt.month);
    const plan = inMemoryDb.plans[planDocId] as MonthlyPlan | undefined;

    const items: DailyCheckInItem[] = [];

    if (plan) {
      plan.dailyRoutines.forEach((routine: any) => {
        items.push({
          id: uuidv4(),
          routineId: routine.id,
          name: routine.name,
          amount: routine.amount,
          type: 'daily',
          status: 'pending',
        });
      });

      plan.weeklyRoutines.forEach((routine: any) => {
        items.push({
          id: uuidv4(),
          routineId: routine.id,
          name: routine.name,
          amount: routine.amount,
          type: 'weekly',
          status: 'pending',
        });
      });
    }

    const now = new Date().toISOString();
    const newLog: DailyLog = {
      id: docId,
      userId,
      date: dateStr,
      items,
      unexpectedExpenses: [],
      createdAt: now,
      updatedAt: now,
    };

    inMemoryDb.dailyLogs[docId] = newLog;
    return newLog;
  }

  public static async updateCheckInStatus(
    userId: string,
    dto: CheckInStatusDTO,
    targetDate?: string
  ): Promise<{ dailyLog: DailyLog; updatedItem: DailyCheckInItem }> {
    const dateStr = targetDate || DateTime.now().setZone('Asia/Ho_Chi_Minh').toISODate()!;
    const docId = this.getDailyLogDocId(userId, dateStr);
    
    const dailyLog = inMemoryDb.dailyLogs[docId];
    if (!dailyLog) {
      throw new AppError(MESSAGES.DAILY.LOG_NOT_FOUND, HTTP_STATUS.NOT_FOUND);
    }

    const itemIndex = dailyLog.items.findIndex((item: any) => item.id === dto.itemId);
    if (itemIndex === -1) {
      throw new AppError(MESSAGES.DAILY.ITEM_NOT_FOUND, HTTP_STATUS.NOT_FOUND);
    }

    const targetItem = dailyLog.items[itemIndex]!;
    const oldStatus = targetItem.status;
    const newStatus = dto.status;

    if (oldStatus === newStatus) {
      return { dailyLog, updatedItem: targetItem };
    }

    targetItem.status = newStatus;
    dailyLog.updatedAt = new Date().toISOString();

    let deltaActualSpent = 0;
    let deltaSavedAmount = 0;

    if (oldStatus === 'pending' && newStatus === 'completed') {
      deltaActualSpent += targetItem.amount;
    } else if (oldStatus === 'pending' && newStatus === 'skipped') {
      deltaSavedAmount += targetItem.amount;
      deltaActualSpent -= targetItem.amount;
    } else if (oldStatus === 'completed' && newStatus === 'skipped') {
      deltaActualSpent -= targetItem.amount * 2;
      deltaSavedAmount += targetItem.amount;
    } else if (oldStatus === 'skipped' && newStatus === 'completed') {
      deltaSavedAmount -= targetItem.amount;
      deltaActualSpent += targetItem.amount * 2;
    }

    const dt = DateTime.fromISO(dateStr);
    const planDocId = PlanService.getPlanDocId(userId, dt.year, dt.month);
    const plan = inMemoryDb.plans[planDocId] as MonthlyPlan | undefined;

    if (plan && (deltaActualSpent !== 0 || deltaSavedAmount !== 0)) {
      plan.actualSpent = Math.round((plan.actualSpent + deltaActualSpent) * 100) / 100;
      plan.savedAmount = Math.round((plan.savedAmount + deltaSavedAmount) * 100) / 100;
      plan.updatedAt = new Date().toISOString();
    }

    return {
      dailyLog,
      updatedItem: targetItem,
    };
  }

  public static async addUnexpectedExpense(
    userId: string,
    dto: UnexpectedExpenseDTO,
    targetDate?: string
  ): Promise<{ dailyLog: DailyLog; expense: UnexpectedExpense }> {
    const dateStr = targetDate || DateTime.now().setZone('Asia/Ho_Chi_Minh').toISODate()!;
    const docId = this.getDailyLogDocId(userId, dateStr);
    
    let dailyLog = inMemoryDb.dailyLogs[docId];
    if (!dailyLog) {
      dailyLog = {
        id: docId,
        userId,
        date: dateStr,
        items: [],
        unexpectedExpenses: [],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      inMemoryDb.dailyLogs[docId] = dailyLog;
    }

    const newExpense: UnexpectedExpense = {
      id: uuidv4(),
      amount: dto.amount,
      reason: dto.reason,
      createdAt: new Date().toISOString(),
    };

    dailyLog.unexpectedExpenses.push(newExpense);
    dailyLog.updatedAt = new Date().toISOString();

    const dt = DateTime.fromISO(dateStr);
    const planDocId = PlanService.getPlanDocId(userId, dt.year, dt.month);
    const plan = inMemoryDb.plans[planDocId] as MonthlyPlan | undefined;

    if (plan) {
      plan.actualSpent = Math.round((plan.actualSpent + dto.amount) * 100) / 100;
      plan.savedAmount = Math.round((plan.totalPlanned - plan.actualSpent) * 100) / 100;
      plan.updatedAt = new Date().toISOString();
    }

    return {
      dailyLog,
      expense: newExpense,
    };
  }
}
