import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';
import { HTTP_STATUS } from '../constants/statusCodes';

type ValidationTarget = 'body' | 'query' | 'params';

export const validateRequest = (schema: ZodSchema, target: ValidationTarget = 'body') => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      const parsedData = schema.parse(req[target]);
      req[target] = parsedData;
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const formattedErrors = error.errors.map((err) => ({
          field: err.path.join('.'),
          message: err.message,
        }));

        res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Validation failed',
          errors: formattedErrors,
        });
        return;
      }

      next(error);
    }
  };
};
