import { Router } from 'express';
import { ReportController } from '../controllers/reportController';
import { authMiddleware } from '../middlewares/authMiddleware';
import { validateRequest } from '../middlewares/zodValidator';
import { reportQuerySchema } from '../models/report.model';

const router = Router();

router.use(authMiddleware);

// GET /api/reports/monthly - Performance data report
router.get('/monthly', validateRequest(reportQuerySchema, 'query'), ReportController.getMonthlyReport);

// GET /api/reports/history - Daily breakdown timeline history
router.get('/history', validateRequest(reportQuerySchema, 'query'), ReportController.getDailyHistory);

export default router;
