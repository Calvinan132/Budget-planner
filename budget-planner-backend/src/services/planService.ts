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

  /**
   * Tính tổng chi phí dự kiến theo toàn bộ tháng (dùng làm tham chiếu, không phải giá trị hiển thị).
   */
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

  /**
   * Tính tổng chi phí dự kiến theo số ngày cụ thể (ví dụ: số ngày còn lại trong tháng).
   * Đây là hàm chính xác để tính kế hoạch khi tạo giữa tháng.
   */
  public static calculateTotalPlannedForDays(
    activeDays: number,
    dailyRoutines: DailyRoutine[],
    weeklyRoutines: WeeklyRoutine[],
    monthlyFixed: MonthlyFixed[]
  ): number {
    const weeks = activeDays / 7.0;
    const dailySum = dailyRoutines.reduce((acc, item) => acc + item.amount, 0) * activeDays;
    const weeklySum = weeklyRoutines.reduce((acc, item) => acc + item.amount * item.frequencyPerWeek * weeks, 0);
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

    // Xác định ngày bắt đầu tính kế hoạch và số ngày hiệu lực
    const startDay = (data as any).startDay || nowVietnam.day;
    const daysInMonth = new Date(year, month, 0).getDate();
    const activeDays = (data as any).activeDays || (daysInMonth - startDay + 1);

    // Ưu tiên dùng totalPlanned từ client (đã tính đúng theo số ngày còn lại).
    // Chỉ tự tính lại nếu client không gửi.
    const totalPlanned = (data as any).totalPlanned > 0
      ? (data as any).totalPlanned
      : this.calculateTotalPlannedForDays(activeDays, dailyRoutines, weeklyRoutines, monthlyFixed);

    const initialBudget = data.initialBudget !== undefined ? data.initialBudget : totalPlanned;
    const actualSpent = 0;
    // Tiền tiết kiệm = Số tiền người dùng nhập đầu tháng - Số tiền tiêu dự kiến theo kế hoạch
    const savedAmount = Math.round((initialBudget - totalPlanned) * 100) / 100;
    const now = new Date().toISOString();

    const newPlan: MonthlyPlan = {
      id: docId,
      userId,
      month,
      year,
      startDay,
      activeDays,
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

    // ⚡ SHORT-CIRCUIT: Trả về ngay cho dev_user_monitor TRƯỚC khi gọi Firestore (tránh timeout 80s)
    if (userId === 'dev_user_monitor') {
      if (inMemoryDb.plans[docId]) {
        return inMemoryDb.plans[docId];
      }
      const samplePlan: MonthlyPlan = {
        id: docId,
        userId,
        month: targetMonth,
        year: targetYear,
        startDay: 1,
        activeDays: new Date(targetYear, targetMonth, 0).getDate(),
        initialBudget: 15000000,
        totalPlanned: 12000000,
        actualSpent: 0,
        savedAmount: 3000000,
        isLocked: false,
        dailyRoutines: [
          { id: 'd1', name: 'Ăn uống hàng ngày', amount: 60000 },
          { id: 'd2', name: 'Cà phê / Giải trí', amount: 35000 }
        ],
        weeklyRoutines: [
          { id: 'w1', name: 'Xăng xe di chuyển', amount: 100000, frequencyPerWeek: 1 }
        ],
        monthlyFixed: [
          { id: 'm1', name: 'Tiền thuê trọ & dịch vụ', amount: 4000000 }
        ],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      inMemoryDb.plans[docId] = samplePlan;
      return samplePlan;
    }

    // ⚡ SHORT-CIRCUIT: Có trong inMemoryDb rồi thì không cần gọi Firestore
    if (inMemoryDb.plans[docId]) {
      return inMemoryDb.plans[docId];
    }

    // Gọi Firestore cho real users
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

    throw new AppError(MESSAGES.PLAN.NOT_FOUND, HTTP_STATUS.NOT_FOUND);
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

    const totalPlanned = (data as any).totalPlanned > 0
      ? (data as any).totalPlanned
      : (() => {
          const startDay = (data as any).startDay || currentPlan.startDay || 1;
          const daysInMonth = new Date(targetYear, targetMonth, 0).getDate();
          const activeDays = (data as any).activeDays || currentPlan.activeDays || (daysInMonth - startDay + 1);
          return this.calculateTotalPlannedForDays(activeDays, dailyRoutines, weeklyRoutines, monthlyFixed);
        })();
    const initialBudget = data.initialBudget !== undefined ? data.initialBudget : (currentPlan.initialBudget ?? totalPlanned);
    // Tiền tiết kiệm = initialBudget - totalPlanned + (các khoản đã skipped - phát sinh)
    // Để bảo toàn các delta skipped/unexpected trước đó:
    const baseSavingsChange = (initialBudget - totalPlanned) - ((currentPlan.initialBudget ?? currentPlan.totalPlanned) - currentPlan.totalPlanned);
    const savedAmount = Math.round((currentPlan.savedAmount + baseSavingsChange) * 100) / 100;
    const updatedAt = new Date().toISOString();

    const updatedStartDay = (data as any).startDay ?? currentPlan.startDay ?? 1;
    const updatedActiveDays = (data as any).activeDays ?? currentPlan.activeDays ?? (new Date(targetYear, targetMonth, 0).getDate() - updatedStartDay + 1);

    const updatedPlan: MonthlyPlan = {
      ...currentPlan,
      startDay: updatedStartDay,
      activeDays: updatedActiveDays,
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

