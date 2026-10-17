import { Request, Response, NextFunction } from 'express';
import { ReportService } from '../services/reportService';
import { HTTP_STATUS } from '../constants/statusCodes';
import { MESSAGES } from '../constants/messages';
import { ReportQueryDTO } from '../models/report.model';

export class ReportController {
  public static getMonthlyReport = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.uid;
      const query = req.query as unknown as ReportQueryDTO;

      const report = await ReportService.getMonthlyReport(userId, query.month, query.year);

      res.status(HTTP_STATUS.OK).json({
        success: true,
        message: MESSAGES.REPORT.MONTHLY_SUCCESS,
        data: report,
      });
    } catch (error) {
      next(error);
    }
  };

  public static getDailyHistory = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.uid;
      const query = req.query as unknown as ReportQueryDTO;

      const history = await ReportService.getDailyHistory(userId, query.month, query.year);

      res.status(HTTP_STATUS.OK).json({
        success: true,
        message: MESSAGES.REPORT.HISTORY_SUCCESS,
        data: history,
      });
    } catch (error) {
      next(error);
    }
  };
}
