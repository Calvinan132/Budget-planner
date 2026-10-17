import { v4 as uuidv4 } from 'uuid';
import { DateTime } from 'luxon';
import { CreatePlanDTO, MonthlyPlan, UpdatePlanDTO, DailyRoutine, WeeklyRoutine, MonthlyFixed } from '../models/plan.model';
import { AppError } from '../middlewares/errorHandler';
import { HTTP_STATUS } from '../constants/statusCodes';
import { MESSAGES } from '../constants/messages';
import { inMemoryDb } from '../config/inMemoryDb';

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
    const docId = this.getPlanDocId(userId, data.year, data.month);
    
    if (inMemoryDb.plans[docId]) {
      throw new AppError(MESSAGES.PLAN.ALREADY_EXISTS, HTTP_STATUS.CONFLICT);
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

    const totalPlanned = this.calculateTotalPlanned(data.month, data.year, dailyRoutines, weeklyRoutines, monthlyFixed);
    const actualSpent = 0;
    const savedAmount = totalPlanned;
    const now = new Date().toISOString();

    const newPlan: MonthlyPlan = {
      id: docId,
      userId,
      month: data.month,
      year: data.year,
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
    return newPlan;
  }

  public static async getCurrentPlan(userId: string, month?: number, year?: number): Promise<MonthlyPlan> {
    const nowVietnam = DateTime.now().setZone('Asia/Ho_Chi_Minh');
    const targetMonth = month || nowVietnam.month;
    const targetYear = year || nowVietnam.year;

    const docId = this.getPlanDocId(userId, targetYear, targetMonth);
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

    const docId = this.getPlanDocId(userId, targetYear, targetMonth);
    const currentPlan = inMemoryDb.plans[docId];

    if (!currentPlan) {
      throw new AppError(MESSAGES.PLAN.NOT_FOUND, HTTP_STATUS.NOT_FOUND);
    }

    if (currentPlan.isLocked) {
      throw new AppError('Monthly plan is locked and cannot be updated', HTTP_STATUS.FORBIDDEN);
    }

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
    const savedAmount = Math.round((totalPlanned - currentPlan.actualSpent) * 100) / 100;
    const updatedAt = new Date().toISOString();

    const updatedPlan: MonthlyPlan = {
      ...currentPlan,
      totalPlanned,
      savedAmount,
      isLocked: data.isLocked ?? currentPlan.isLocked,
      dailyRoutines,
      weeklyRoutines,
      monthlyFixed,
      updatedAt,
    };

    inMemoryDb.plans[docId] = updatedPlan;
    return updatedPlan;
  }
}
