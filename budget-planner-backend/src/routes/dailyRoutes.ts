import { Router } from 'express';
import { DailyLogController } from '../controllers/dailyLogController';
import { authMiddleware } from '../middlewares/authMiddleware';
import { validateRequest } from '../middlewares/zodValidator';
import { checkInStatusSchema, unexpectedExpenseSchema } from '../models/dailyLog.model';

const router = Router();

router.use(authMiddleware);

// GET /api/daily/today - Get today's check-in items (auto populates if missing)
router.get('/today', DailyLogController.getToday);

// PATCH /api/daily/check-in - Update item status (completed/skipped with transaction)
router.patch('/check-in', validateRequest(checkInStatusSchema, 'body'), DailyLogController.checkInItem);

// POST /api/daily/unexpected-expense - Log unexpected spending (with transaction)
router.post(
  '/unexpected-expense',
  validateRequest(unexpectedExpenseSchema, 'body'),
  DailyLogController.addUnexpectedExpense
);

export default router;
