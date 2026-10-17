import { Request, Response, NextFunction } from 'express';
import { DailyLogService } from '../services/dailyLogService';
import { HTTP_STATUS } from '../constants/statusCodes';
import { MESSAGES } from '../constants/messages';
import { CheckInStatusDTO, UnexpectedExpenseDTO } from '../models/dailyLog.model';

export class DailyLogController {
  public static getToday = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.uid;
      const targetDate = req.query.date as string | undefined;

      const dailyLog = await DailyLogService.getTodayLog(userId, targetDate);

      res.status(HTTP_STATUS.OK).json({
        success: true,
        message: MESSAGES.DAILY.LOG_RETRIEVED,
        data: dailyLog,
      });
    } catch (error) {
      next(error);
    }
  };

  public static checkInItem = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.uid;
      const dto: CheckInStatusDTO = req.body;
      const targetDate = req.query.date as string | undefined;

      const result = await DailyLogService.updateCheckInStatus(userId, dto, targetDate);

      res.status(HTTP_STATUS.OK).json({
        success: true,
        message: MESSAGES.DAILY.CHECK_IN_SUCCESS,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  };

  public static addUnexpectedExpense = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.uid;
      const dto: UnexpectedExpenseDTO = req.body;
      const targetDate = req.query.date as string | undefined;

      const result = await DailyLogService.addUnexpectedExpense(userId, dto, targetDate);

      res.status(HTTP_STATUS.CREATED).json({
        success: true,
        message: MESSAGES.DAILY.UNEXPECTED_EXPENSE_SUCCESS,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  };
}
