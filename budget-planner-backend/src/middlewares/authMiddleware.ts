import { Request, Response, NextFunction } from 'express';
import { auth } from '../config/firebase';
import { env } from '../config/env';
import { HTTP_STATUS } from '../constants/statusCodes';
import { MESSAGES } from '../constants/messages';

export interface AuthenticatedUser {
  uid: string;
  email?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

export const authMiddleware = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const authHeader = req.headers.authorization;

  if (env.DEV_AUTH_BYPASS) {
    // Development fallback to allow seamless API testing without Firebase Auth UI setup
    const devUid = (req.headers['x-dev-user-id'] as string) || 'dev_test_user_123';
    req.user = {
      uid: devUid,
      email: `${devUid}@example.com`,
    };
    return next();
  }

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(HTTP_STATUS.UNAUTHORIZED).json({
      success: false,
      message: MESSAGES.USER.UNAUTHORIZED,
    });
    return;
  }

  const token = authHeader.split('Bearer ')[1]?.trim();

  if (!token) {
    res.status(HTTP_STATUS.UNAUTHORIZED).json({
      success: false,
      message: MESSAGES.USER.UNAUTHORIZED,
    });
    return;
  }

  try {
    const decodedToken = await auth.verifyIdToken(token);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
    };
    next();
  } catch (error) {
    console.error('[AuthMiddleware] Token verification failed:', error);
    res.status(HTTP_STATUS.UNAUTHORIZED).json({
      success: false,
      message: MESSAGES.USER.UNAUTHORIZED,
    });
  }
};
