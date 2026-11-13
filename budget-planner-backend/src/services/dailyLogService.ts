import { v4 as uuidv4 } from 'uuid';
import { DateTime } from 'luxon';
import { CheckInStatusDTO, DailyCheckInItem, DailyLog, UnexpectedExpense, UnexpectedExpenseDTO } from '../models/dailyLog.model';
import { MonthlyPlan } from '../models/plan.model';
import { AppError } from '../middlewares/errorHandler';
import { HTTP_STATUS } from '../constants/statusCodes';
import { MESSAGES } from '../constants/messages';
import { PlanService } from './planService';
import { inMemoryDb } from '../config/inMemoryDb';
import { db } from '../config/firebase';

const DAILY_LOGS_COLLECTION = 'daily_logs';
const PLANS_COLLECTION = 'monthly_plans';

export class DailyLogService {
  public static getDailyLogDocId(userId: string, dateStr: string): string {
    const sanitizedDate = dateStr.replace(/-/g, '_');
    return `${userId}_${sanitizedDate}`;
  }

  public static async getTodayLog(userId: string, targetDate?: string): Promise<DailyLog> {
    const dateStr = targetDate || DateTime.now().setZone('Asia/Ho_Chi_Minh').toISODate()!;
    const docId = this.getDailyLogDocId(userId, dateStr);

    // ⚡ SHORT-CIRCUIT: Có trong inMemoryDb rồi thì trả về ngay (tránh Firestore timeout)
    if (inMemoryDb.dailyLogs[docId]) {
      return inMemoryDb.dailyLogs[docId];
    }

    // ⚡ SHORT-CIRCUIT: Với dev_user_monitor, tạo luôn daily log mẫu mà không gọi Firestore
    if (userId === 'dev_user_monitor') {
      const dt = DateTime.fromISO(dateStr);
      let plan: MonthlyPlan | undefined;
      try {
        plan = await PlanService.getCurrentPlan(userId, dt.month, dt.year);
      } catch (_) {}

      const items: DailyCheckInItem[] = [];
      if (plan) {
        plan.dailyRoutines.forEach((routine: any) => {
          items.push({ id: uuidv4(), routineId: routine.id, name: routine.name, amount: routine.amount, type: 'daily', status: 'pending' });
        });
        plan.weeklyRoutines.forEach((routine: any) => {
          items.push({ id: uuidv4(), routineId: routine.id, name: routine.name, amount: routine.amount, type: 'weekly', status: 'pending' });
        });
      }

      const now = new Date().toISOString();
      const newLog: DailyLog = { id: docId, userId, date: dateStr, items, unexpectedExpenses: [], createdAt: now, updatedAt: now };
      inMemoryDb.dailyLogs[docId] = newLog;
      return newLog;
    }

    // 1. Try reading from Firestore for real users
    try {
      const logDoc = await db.collection(DAILY_LOGS_COLLECTION).doc(docId).get();
      if (logDoc.exists) {
        const log = logDoc.data() as DailyLog;
        inMemoryDb.dailyLogs[docId] = log;
        return log;
      }
    } catch (err) {
      console.warn('[DailyLogService] Firestore getTodayLog failed, trying inMemoryDb:', err);
    }

    // 2. Not exists: generate from MonthlyPlan
    const dt = DateTime.fromISO(dateStr);
    let plan: MonthlyPlan | undefined;
    try {
      plan = await PlanService.getCurrentPlan(userId, dt.month, dt.year);
    } catch (_) {
      // Plan might not exist yet
    }

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
    try {
      await db.collection(DAILY_LOGS_COLLECTION).doc(docId).set(newLog);
    } catch (err) {
      console.warn('[DailyLogService] Firestore create today log failed, stored in inMemoryDb:', err);
    }

    return newLog;
  }

  public static async updateCheckInStatus(
    userId: string,
    dto: CheckInStatusDTO,
    targetDate?: string
  ): Promise<{ dailyLog: DailyLog; updatedItem: DailyCheckInItem }> {
    const dateStr = targetDate || DateTime.now().setZone('Asia/Ho_Chi_Minh').toISODate()!;
    const logDocId = this.getDailyLogDocId(userId, dateStr);
    const dt = DateTime.fromISO(dateStr);
    const planDocId = PlanService.getPlanDocId(userId, dt.year, dt.month);

    const logRef = db.collection(DAILY_LOGS_COLLECTION).doc(logDocId);
    const planRef = db.collection(PLANS_COLLECTION).doc(planDocId);

    // Try executing with Firestore Atomic Transaction
    try {
      return await db.runTransaction(async (transaction) => {
        // 1. ALL READS FIRST (Bắt buộc theo quy tắc Firestore Transaction)
        const logDoc = await transaction.get(logRef);
        const planDoc = await transaction.get(planRef);

        let dailyLog = logDoc.exists ? (logDoc.data() as DailyLog) : inMemoryDb.dailyLogs[logDocId];

        if (!dailyLog) {
          throw new AppError(MESSAGES.DAILY.LOG_NOT_FOUND, HTTP_STATUS.NOT_FOUND);
        }

        const itemIndex = dailyLog.items.findIndex((item: DailyCheckInItem) => item.id === dto.itemId);
        if (itemIndex === -1) {
          throw new AppError(MESSAGES.DAILY.ITEM_NOT_FOUND, HTTP_STATUS.NOT_FOUND);
        }

        const targetItem = dailyLog.items[itemIndex]!;
        const oldStatus = targetItem.status;
        const newStatus = dto.status;

        if (oldStatus === newStatus) {
          return { dailyLog, updatedItem: targetItem };
        }

        // Calculate delta
        let deltaActualSpent = 0;
        let deltaSavedAmount = 0;

        // actualSpent = tiền thực chi ("Có tiêu"); skipped không trừ actualSpent
        // khi khoản đó chưa từng được chi → tránh actualSpent thành số âm.
        if (oldStatus === 'pending' && newStatus === 'completed') {
          deltaActualSpent += targetItem.amount;
        } else if (oldStatus === 'pending' && newStatus === 'skipped') {
          deltaSavedAmount += targetItem.amount;
        } else if (oldStatus === 'completed' && newStatus === 'skipped') {
          deltaActualSpent -= targetItem.amount;
          deltaSavedAmount += targetItem.amount;
        } else if (oldStatus === 'skipped' && newStatus === 'completed') {
          deltaSavedAmount -= targetItem.amount;
          deltaActualSpent += targetItem.amount;
        } else if (oldStatus === 'completed' && newStatus === 'pending') {
          deltaActualSpent -= targetItem.amount;
        } else if (oldStatus === 'skipped' && newStatus === 'pending') {
          deltaSavedAmount -= targetItem.amount;
        }

        targetItem.status = newStatus;
        dailyLog.updatedAt = new Date().toISOString();

        // 2. ALL WRITES AFTER READS
        transaction.set(logRef, dailyLog, { merge: true });

        if (planDoc.exists && (deltaActualSpent !== 0 || deltaSavedAmount !== 0)) {
          const plan = planDoc.data() as MonthlyPlan;
          const updatedPlan = {
            ...plan,
            actualSpent: Math.max(0, Math.round((plan.actualSpent + deltaActualSpent) * 100) / 100),
            savedAmount: Math.max(0, Math.round((plan.savedAmount + deltaSavedAmount) * 100) / 100),
            updatedAt: new Date().toISOString(),
          };
          transaction.set(planRef, updatedPlan, { merge: true });
          inMemoryDb.plans[planDocId] = updatedPlan;
        }

        inMemoryDb.dailyLogs[logDocId] = dailyLog;
        return { dailyLog, updatedItem: targetItem };
      });
    } catch (err: any) {
      if (err instanceof AppError) throw err;
      console.warn('[DailyLogService] Firestore transaction failed, falling back to inMemoryDb:', err);

      // In-Memory Fallback Execution
      const dailyLog = inMemoryDb.dailyLogs[logDocId];
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

      // Same semantics as transaction branch above (no negative actualSpent).
      if (oldStatus === 'pending' && newStatus === 'completed') {
        deltaActualSpent += targetItem.amount;
      } else if (oldStatus === 'pending' && newStatus === 'skipped') {
        deltaSavedAmount += targetItem.amount;
      } else if (oldStatus === 'completed' && newStatus === 'skipped') {
        deltaActualSpent -= targetItem.amount;
        deltaSavedAmount += targetItem.amount;
      } else if (oldStatus === 'skipped' && newStatus === 'completed') {
        deltaSavedAmount -= targetItem.amount;
        deltaActualSpent += targetItem.amount;
      } else if (oldStatus === 'completed' && newStatus === 'pending') {
        deltaActualSpent -= targetItem.amount;
      } else if (oldStatus === 'skipped' && newStatus === 'pending') {
        deltaSavedAmount -= targetItem.amount;
      }

      const plan = inMemoryDb.plans[planDocId] as MonthlyPlan | undefined;
      if (plan && (deltaActualSpent !== 0 || deltaSavedAmount !== 0)) {
        plan.actualSpent = Math.max(0, Math.round((plan.actualSpent + deltaActualSpent) * 100) / 100);
        plan.savedAmount = Math.max(0, Math.round((plan.savedAmount + deltaSavedAmount) * 100) / 100);
        plan.updatedAt = new Date().toISOString();
      }

      return { dailyLog, updatedItem: targetItem };
    }
  }

  public static async addUnexpectedExpense(
    userId: string,
    dto: UnexpectedExpenseDTO,
    targetDate?: string
  ): Promise<{ dailyLog: DailyLog; expense: UnexpectedExpense }> {
    const dateStr = targetDate || DateTime.now().setZone('Asia/Ho_Chi_Minh').toISODate()!;
    const logDocId = this.getDailyLogDocId(userId, dateStr);
    const dt = DateTime.fromISO(dateStr);
    const planDocId = PlanService.getPlanDocId(userId, dt.year, dt.month);

    const newExpense: UnexpectedExpense = {
      id: uuidv4(),
      amount: dto.amount,
      reason: dto.reason,
      createdAt: new Date().toISOString(),
    };

    const logRef = db.collection(DAILY_LOGS_COLLECTION).doc(logDocId);
    const planRef = db.collection(PLANS_COLLECTION).doc(planDocId);

    try {
      return await db.runTransaction(async (transaction) => {
        // 1. ALL READS FIRST
        const logDoc = await transaction.get(logRef);
        const planDoc = await transaction.get(planRef);

        let dailyLog = logDoc.exists ? (logDoc.data() as DailyLog) : inMemoryDb.dailyLogs[logDocId];

        if (!dailyLog) {
          dailyLog = {
            id: logDocId,
            userId,
            date: dateStr,
            items: [],
            unexpectedExpenses: [],
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          };
        }

        dailyLog.unexpectedExpenses.push(newExpense);
        dailyLog.updatedAt = new Date().toISOString();

        // 2. ALL WRITES AFTER READS
        transaction.set(logRef, dailyLog, { merge: true });

        if (planDoc.exists) {
          const plan = planDoc.data() as MonthlyPlan;
          const updatedPlan = {
            ...plan,
            actualSpent: Math.round((plan.actualSpent + dto.amount) * 100) / 100,
            // Heo đất trừ đi khoản chi phát sinh theo công thức người dùng yêu cầu: - (Số tiền hoạt động phát sinh trong ngày)
            savedAmount: Math.round((plan.savedAmount - dto.amount) * 100) / 100,
            updatedAt: new Date().toISOString(),
          };
          transaction.set(planRef, updatedPlan, { merge: true });
          inMemoryDb.plans[planDocId] = updatedPlan;
        }

        inMemoryDb.dailyLogs[logDocId] = dailyLog;
        return { dailyLog, expense: newExpense };
      });
    } catch (err) {
      console.warn('[DailyLogService] Firestore addUnexpectedExpense failed, falling back to inMemoryDb:', err);

      let dailyLog = inMemoryDb.dailyLogs[logDocId];
      if (!dailyLog) {
        dailyLog = {
          id: logDocId,
          userId,
          date: dateStr,
          items: [],
          unexpectedExpenses: [],
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        inMemoryDb.dailyLogs[logDocId] = dailyLog;
      }

      dailyLog.unexpectedExpenses.push(newExpense);
      dailyLog.updatedAt = new Date().toISOString();

      const plan = inMemoryDb.plans[planDocId] as MonthlyPlan | undefined;
      if (plan) {
        plan.actualSpent = Math.round((plan.actualSpent + dto.amount) * 100) / 100;
        plan.savedAmount = Math.round((plan.savedAmount - dto.amount) * 100) / 100;
        plan.updatedAt = new Date().toISOString();
      }

      return { dailyLog, expense: newExpense };
    }
  }

  /**
   * Update amount / reason of an existing unexpected expense (chỉ chỉnh delta actualSpent)
   */
  public static async updateUnexpectedExpense(
    userId: string,
    expenseId: string,
    dto: UnexpectedExpenseDTO,
    targetDate?: string
  ): Promise<{ dailyLog: DailyLog; updatedExpense: UnexpectedExpense }> {
    const dateStr = targetDate || DateTime.now().setZone('Asia/Ho_Chi_Minh').toISODate()!;
    const logDocId = this.getDailyLogDocId(userId, dateStr);
    const dt = DateTime.fromISO(dateStr);
    const planDocId = PlanService.getPlanDocId(userId, dt.year, dt.month);

    const logRef = db.collection(DAILY_LOGS_COLLECTION).doc(logDocId);
    const planRef = db.collection(PLANS_COLLECTION).doc(planDocId);

    try {
      return await db.runTransaction(async (transaction) => {
        // 1. ALL READS FIRST
        const logDoc = await transaction.get(logRef);
        const planDoc = await transaction.get(planRef);

        const dailyLog = logDoc.exists ? (logDoc.data() as DailyLog) : inMemoryDb.dailyLogs[logDocId];

        if (!dailyLog) {
          throw new AppError(MESSAGES.DAILY.LOG_NOT_FOUND, HTTP_STATUS.NOT_FOUND);
        }

        const expIndex = dailyLog.unexpectedExpenses.findIndex((e: UnexpectedExpense) => e.id === expenseId);
        if (expIndex === -1) {
          throw new AppError('Unexpected expense not found', HTTP_STATUS.NOT_FOUND);
        }

        const oldExpense = dailyLog.unexpectedExpenses[expIndex]!;
        const delta = Math.round((dto.amount - oldExpense.amount) * 100) / 100;
        const updatedExpense: UnexpectedExpense = {
          ...oldExpense,
          amount: dto.amount,
          reason: dto.reason,
        };
        dailyLog.unexpectedExpenses[expIndex] = updatedExpense;
        dailyLog.updatedAt = new Date().toISOString();

        // 2. ALL WRITES AFTER READS
        transaction.set(logRef, dailyLog, { merge: true });

        if (delta !== 0 && planDoc.exists) {
          const plan = planDoc.data() as MonthlyPlan;
          const updatedPlan = {
            ...plan,
            actualSpent: Math.max(0, Math.round((plan.actualSpent + delta) * 100) / 100),
            savedAmount: Math.round((plan.savedAmount - delta) * 100) / 100,
            updatedAt: new Date().toISOString(),
          };
          transaction.set(planRef, updatedPlan, { merge: true });
          inMemoryDb.plans[planDocId] = updatedPlan;
        }

        inMemoryDb.dailyLogs[logDocId] = dailyLog;
        return { dailyLog, updatedExpense };
      });
    } catch (err: any) {
      if (err instanceof AppError) throw err;
      console.warn('[DailyLogService] Firestore updateUnexpectedExpense failed, falling back to inMemoryDb:', err);

      const dailyLog = inMemoryDb.dailyLogs[logDocId];
      if (!dailyLog) {
        throw new AppError(MESSAGES.DAILY.LOG_NOT_FOUND, HTTP_STATUS.NOT_FOUND);
      }

      const expIndex = dailyLog.unexpectedExpenses.findIndex((e: UnexpectedExpense) => e.id === expenseId);
      if (expIndex === -1) {
        throw new AppError('Unexpected expense not found', HTTP_STATUS.NOT_FOUND);
      }

      const oldExpense = dailyLog.unexpectedExpenses[expIndex]!;
      const delta = Math.round((dto.amount - oldExpense.amount) * 100) / 100;
      const updatedExpense: UnexpectedExpense = {
        ...oldExpense,
        amount: dto.amount,
        reason: dto.reason,
      };
      dailyLog.unexpectedExpenses[expIndex] = updatedExpense;
      dailyLog.updatedAt = new Date().toISOString();

      const plan = inMemoryDb.plans[planDocId] as MonthlyPlan | undefined;
      if (plan && delta !== 0) {
        plan.actualSpent = Math.max(0, Math.round((plan.actualSpent + delta) * 100) / 100);
        plan.savedAmount = Math.round((plan.savedAmount - delta) * 100) / 100;
        plan.updatedAt = new Date().toISOString();
      }

      return { dailyLog, updatedExpense };
    }
  }

  /**
   * Delete / Undo an unexpected expense
   */
  public static async deleteUnexpectedExpense(
    userId: string,
    expenseId: string,
    targetDate?: string
  ): Promise<{ dailyLog: DailyLog; deletedExpense: UnexpectedExpense }> {
    const dateStr = targetDate || DateTime.now().setZone('Asia/Ho_Chi_Minh').toISODate()!;
    const logDocId = this.getDailyLogDocId(userId, dateStr);
    const dt = DateTime.fromISO(dateStr);
    const planDocId = PlanService.getPlanDocId(userId, dt.year, dt.month);

    const logRef = db.collection(DAILY_LOGS_COLLECTION).doc(logDocId);
    const planRef = db.collection(PLANS_COLLECTION).doc(planDocId);

    try {
      return await db.runTransaction(async (transaction) => {
        // 1. ALL READS FIRST
        const logDoc = await transaction.get(logRef);
        const planDoc = await transaction.get(planRef);

        const dailyLog = logDoc.exists ? (logDoc.data() as DailyLog) : inMemoryDb.dailyLogs[logDocId];

        if (!dailyLog) {
          throw new AppError(MESSAGES.DAILY.LOG_NOT_FOUND, HTTP_STATUS.NOT_FOUND);
        }

        const expIndex = dailyLog.unexpectedExpenses.findIndex((e: UnexpectedExpense) => e.id === expenseId);
        if (expIndex === -1) {
          throw new AppError('Unexpected expense not found', HTTP_STATUS.NOT_FOUND);
        }

        const [deletedExpense] = dailyLog.unexpectedExpenses.splice(expIndex, 1);
        dailyLog.updatedAt = new Date().toISOString();

        // 2. ALL WRITES AFTER READS
        transaction.set(logRef, dailyLog, { merge: true });

        if (planDoc.exists && deletedExpense) {
          const plan = planDoc.data() as MonthlyPlan;
          const updatedPlan = {
            ...plan,
            actualSpent: Math.max(0, Math.round((plan.actualSpent - deletedExpense.amount) * 100) / 100),
            savedAmount: Math.round((plan.savedAmount + deletedExpense.amount) * 100) / 100,
            updatedAt: new Date().toISOString(),
          };
          transaction.set(planRef, updatedPlan, { merge: true });
          inMemoryDb.plans[planDocId] = updatedPlan;
        }

        inMemoryDb.dailyLogs[logDocId] = dailyLog;
        return { dailyLog, deletedExpense: deletedExpense! };
      });
    } catch (err: any) {
      if (err instanceof AppError) throw err;
      const dailyLog = inMemoryDb.dailyLogs[logDocId];
      if (!dailyLog) {
        throw new AppError(MESSAGES.DAILY.LOG_NOT_FOUND, HTTP_STATUS.NOT_FOUND);
      }

      const expIndex = dailyLog.unexpectedExpenses.findIndex((e: any) => e.id === expenseId);
      if (expIndex === -1) {
        throw new AppError('Unexpected expense not found', HTTP_STATUS.NOT_FOUND);
      }

      const [deletedExpense] = dailyLog.unexpectedExpenses.splice(expIndex, 1);
      dailyLog.updatedAt = new Date().toISOString();

      const plan = inMemoryDb.plans[planDocId] as MonthlyPlan | undefined;
      if (plan && deletedExpense) {
        plan.actualSpent = Math.max(0, Math.round((plan.actualSpent - deletedExpense.amount) * 100) / 100);
        plan.savedAmount = Math.round((plan.savedAmount + deletedExpense.amount) * 100) / 100;
        plan.updatedAt = new Date().toISOString();
      }

      return { dailyLog, deletedExpense: deletedExpense! };
    }
  }
}

