import { Request, Response, NextFunction } from 'express';
import { UserService } from '../services/userService';
import { HTTP_STATUS } from '../constants/statusCodes';
import { MESSAGES } from '../constants/messages';
import { SyncUserDTO } from '../models/user.model';

export class UserController {
  public static syncUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user!.uid;
      const data: SyncUserDTO = req.body;

      const userProfile = await UserService.syncUserProfile(userId, data);

      res.status(HTTP_STATUS.OK).json({
        success: true,
        message: MESSAGES.USER.SYNC_SUCCESS,
        data: userProfile,
      });
    } catch (error) {
      next(error);
    }
  };
}
