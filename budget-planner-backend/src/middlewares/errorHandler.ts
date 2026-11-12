import { Request, Response, NextFunction } from 'express';
import { HTTP_STATUS } from '../constants/statusCodes';
import { MESSAGES } from '../constants/messages';

export class AppError extends Error {
  public readonly statusCode: number;

  constructor(message: string, statusCode: number = HTTP_STATUS.BAD_REQUEST) {
    super(message);
    this.statusCode = statusCode;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export const errorHandler = (
  err: Error | AppError,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  next: NextFunction
): void => {
  const statusCode = err instanceof AppError ? err.statusCode : HTTP_STATUS.INTERNAL_SERVER_ERROR;
  const message = err.message || MESSAGES.SERVER.INTERNAL_ERROR;

  // 404 Not Found (như khi người dùng mới chưa tạo plan tháng này) là luồng nghiệp vụ bình thường
  if (statusCode === HTTP_STATUS.NOT_FOUND) {
    console.info(`[Info]: ${req.method} ${req.originalUrl} - ${message} (User: ${req.user?.uid || 'anonymous'})`);
  } else {
    console.error('[Error Handler]:', err);
  }

  res.status(statusCode).json({
    success: false,
    message: message,
  });
};
