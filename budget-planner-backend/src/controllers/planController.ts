import { Request, Response, NextFunction } from 'express';
import { PlanService } from '../services/planService';
import { HTTP_STATUS } from '../constants/statusCodes';
import { MESSAGES } from '../constants/messages';
import { CreatePlanDTO, UpdatePlanDTO } from '../models/plan.model';

export class PlanController {
  public static createPlan = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.uid;
      const data: CreatePlanDTO = req.body;

      const plan = await PlanService.createPlan(userId, data);

      res.status(HTTP_STATUS.CREATED).json({
        success: true,
        message: MESSAGES.PLAN.CREATED_SUCCESS,
        data: plan,
      });
    } catch (error) {
      next(error);
    }
  };

  public static getCurrentPlan = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.uid;
      const month = req.query.month ? parseInt(req.query.month as string, 10) : undefined;
      const year = req.query.year ? parseInt(req.query.year as string, 10) : undefined;

      const plan = await PlanService.getCurrentPlan(userId, month, year);

      res.status(HTTP_STATUS.OK).json({
        success: true,
        message: 'Active plan retrieved successfully',
        data: plan,
      });
    } catch (error) {
      next(error);
    }
  };

  public static updateCurrentPlan = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.uid;
      const data: UpdatePlanDTO = req.body;

      const plan = await PlanService.updateCurrentPlan(userId, data);

      res.status(HTTP_STATUS.OK).json({
        success: true,
        message: MESSAGES.PLAN.UPDATED_SUCCESS,
        data: plan,
      });
    } catch (error) {
      next(error);
    }
  };
}
