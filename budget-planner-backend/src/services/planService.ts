import { v4 as uuidv4 } from 'uuid';
import { DateTime } from 'luxon';
import { CreatePlanDTO, MonthlyPlan, UpdatePlanDTO, DailyRoutine, WeeklyRoutine, MonthlyFixed } from '../models/plan.model';
import { AppError } from '../middlewares/errorHandler';
import { HTTP_STATUS } from '../constants/statusCodes';
import { MESSAGES } from '../constants/messages';
import { inMemoryDb } from '../config/inMemoryDb';
import { db } from '../config/firebase';

const PLANS_COLLECTION = 'monthly_plans';

export class PlanService {
  public static getPlanDocId(userId: string, year: number, month: number): string {
    const monthStr = month.toString().padStart(2, '0');
    return `${userId}_${year}_${monthStr}`;
  }

  public static calculateTotalPlanned(
    month: number,
    year: number,
    dailyRoutines: DailyRoutine[],
    weeklyRoutines: WeeklyRoutine[],
    monthlyFixed: MonthlyFixed[]
  ): number {
    const daysInMonth = new Date(year, month, 0).getDate();
    const dailySum = dailyRoutines.reduce((acc, item) => acc + item.amount, 0) * daysInMonth;
    const weeklySum = weeklyRoutines.reduce((acc, item) => acc + item.amount * item.frequencyPerWeek * 4.3, 0);
    const fixedSum = monthlyFixed.reduce((acc, item) => acc + item.amount, 0);

    return Math.round((dailySum + weeklySum + fixedSum) * 100) / 100;
  }

  public static async createPlan(userId: string, data: CreatePlanDTO): Promise<MonthlyPlan> {
    // Mặc định tháng/năm theo giờ Việt Nam nếu client không gửi (khớp với getCurrentPlan).
    const nowVietnam = DateTime.now().setZone('Asia/Ho_Chi_Minh');
    const month = data.month || nowVietnam.month;
    const year = data.year || nowVietnam.year;

    const docId = this.getPlanDocId(userId, year, month);

    // 1. Check existing in Firestore / inMemoryDb
    try {
      const docSnap = await db.collection(PLANS_COLLECTION).doc(docId).get();
      if (docSnap.exists || inMemoryDb.plans[docId]) {
        throw new AppError(MESSAGES.PLAN.ALREADY_EXISTS, HTTP_STATUS.CONFLICT);
      }
    } catch (err: any) {
      if (err instanceof AppError) throw err;
      if (inMemoryDb.plans[docId]) {
        throw new AppError(MESSAGES.PLAN.ALREADY_EXISTS, HTTP_STATUS.CONFLICT);
      }
    }

    const dailyRoutines = data.dailyRoutines.map((item) => ({
      id: item.id || uuidv4(),
      name: item.name,
      amount: item.amount,
    }));
    const weeklyRoutines = data.weeklyRoutines.map((item) => ({
      id: item.id || uuidv4(),
      name: item.name,
      amount: item.amount,
      frequencyPerWeek: item.frequencyPerWeek,
    }));
    const monthlyFixed = data.monthlyFixed.map((item) => ({
      id: item.id || uuidv4(),
      name: item.name,
      amount: item.amount,
    }));

    const totalPlanned = this.calculateTotalPlanned(month, year, dailyRoutines, weeklyRoutines, monthlyFixed);
    const initialBudget = data.initialBudget !== undefined ? data.initialBudget : totalPlanned;
    const actualSpent = 0;
    // Tiền tiết kiệm = Số tiền người dùng nhập đầu tháng - Số tiền tiêu dự kiến + số tiền không tiêu - phát sinh
    const savedAmount = Math.round((initialBudget - totalPlanned) * 100) / 100;
    const now = new Date().toISOString();

    const newPlan: MonthlyPlan = {
      id: docId,
      userId,
      month,
      year,
      initialBudget,
      totalPlanned,
      actualSpent,
      savedAmount,
      isLocked: false,
      dailyRoutines,
      weeklyRoutines,
      monthlyFixed,
      createdAt: now,
      updatedAt: now,
    };

    inMemoryDb.plans[docId] = newPlan;
    try {
      await db.collection(PLANS_COLLECTION).doc(docId).set(newPlan);
    } catch (err) {
      console.warn('[PlanService] Firestore set failed, fallback inMemoryDb:', err);
    }

    return newPlan;
  }

  public static async getCurrentPlan(userId: string, month?: number, year?: number): Promise<MonthlyPlan> {
    const nowVietnam = DateTime.now().setZone('Asia/Ho_Chi_Minh');
    const targetMonth = month || nowVietnam.month;
    const targetYear = year || nowVietnam.year;

    const docId = this.getPlanDocId(userId, targetYear, targetMonth);

    // Try Firestore first
    try {
      const docSnap = await db.collection(PLANS_COLLECTION).doc(docId).get();
      if (docSnap.exists) {
        const plan = docSnap.data() as MonthlyPlan;
        inMemoryDb.plans[docId] = plan;
        return plan;
      }
    } catch (err) {
      console.warn('[PlanService] Firestore get failed, fallback to inMemoryDb:', err);
    }

    const plan = inMemoryDb.plans[docId];
    if (!plan) {
      throw new AppError(MESSAGES.PLAN.NOT_FOUND, HTTP_STATUS.NOT_FOUND);
    }

    return plan;
  }

  public static async updateCurrentPlan(userId: string, data: UpdatePlanDTO): Promise<MonthlyPlan> {
    const nowVietnam = DateTime.now().setZone('Asia/Ho_Chi_Minh');
    const targetMonth = data.month || nowVietnam.month;
    const targetYear = data.year || nowVietnam.year;

    const currentPlan = await this.getCurrentPlan(userId, targetMonth, targetYear);

    // Note: Plan adjustments are permitted to allow users to update their budget routines


    const dailyRoutines = data.dailyRoutines
      ? data.dailyRoutines.map((item) => ({
          id: item.id || uuidv4(),
          name: item.name,
          amount: item.amount,
        }))
      : currentPlan.dailyRoutines;

    const weeklyRoutines = data.weeklyRoutines
      ? data.weeklyRoutines.map((item) => ({
          id: item.id || uuidv4(),
          name: item.name,
          amount: item.amount,
          frequencyPerWeek: item.frequencyPerWeek,
        }))
      : currentPlan.weeklyRoutines;

    const monthlyFixed = data.monthlyFixed
      ? data.monthlyFixed.map((item) => ({
          id: item.id || uuidv4(),
          name: item.name,
          amount: item.amount,
        }))
      : currentPlan.monthlyFixed;

    const totalPlanned = this.calculateTotalPlanned(targetMonth, targetYear, dailyRoutines, weeklyRoutines, monthlyFixed);
    const initialBudget = data.initialBudget !== undefined ? data.initialBudget : (currentPlan.initialBudget ?? totalPlanned);
    // Tiền tiết kiệm = initialBudget - totalPlanned + (các khoản đã skipped - phát sinh)
    // Để bảo toàn các delta skipped/unexpected trước đó:
    const baseSavingsChange = (initialBudget - totalPlanned) - ((currentPlan.initialBudget ?? currentPlan.totalPlanned) - currentPlan.totalPlanned);
    const savedAmount = Math.round((currentPlan.savedAmount + baseSavingsChange) * 100) / 100;
    const updatedAt = new Date().toISOString();

    const updatedPlan: MonthlyPlan = {
      ...currentPlan,
      initialBudget,
      totalPlanned,
      savedAmount,
      isLocked: data.isLocked ?? currentPlan.isLocked,
      dailyRoutines,
      weeklyRoutines,
      monthlyFixed,
      updatedAt,
    };

    const docId = currentPlan.id;
    inMemoryDb.plans[docId] = updatedPlan;
    try {
      await db.collection(PLANS_COLLECTION).doc(docId).set(updatedPlan, { merge: true });
    } catch (err) {
      console.warn('[PlanService] Firestore update failed, fallback to inMemoryDb:', err);
    }

    return updatedPlan;
  }

  /**
   * Clone routines and fixed items from previous month to new month
   */
  public static async clonePreviousPlan(
    userId: string,
    targetMonth: number,
    targetYear: number
  ): Promise<MonthlyPlan> {
    const prevDate = DateTime.fromObject({ year: targetYear, month: targetMonth, day: 1 }).minus({ months: 1 });
    const prevPlan = await this.getCurrentPlan(userId, prevDate.month, prevDate.year);

    return this.createPlan(userId, {
      month: targetMonth,
      year: targetYear,
      dailyRoutines: prevPlan.dailyRoutines.map((r) => ({ name: r.name, amount: r.amount })),
      weeklyRoutines: prevPlan.weeklyRoutines.map((w) => ({
        name: w.name,
        amount: w.amount,
        frequencyPerWeek: w.frequencyPerWeek,
      })),
      monthlyFixed: prevPlan.monthlyFixed.map((m) => ({ name: m.name, amount: m.amount })),
    });
  }
}

