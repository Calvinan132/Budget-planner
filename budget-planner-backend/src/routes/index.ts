import { Router } from 'express';
import userRoutes from './userRoutes';
import planRoutes from './planRoutes';
import dailyRoutes from './dailyRoutes';
import reportRoutes from './reportRoutes';
import { flowMonitor } from '../middlewares/flowMonitorMiddleware';

const router = Router();

router.use('/users', flowMonitor('backend_users'), userRoutes);
router.use('/plans', flowMonitor('backend_plans'), planRoutes);
router.use('/daily', flowMonitor('backend_daily'), dailyRoutes);
router.use('/reports', flowMonitor('backend_reports'), reportRoutes);

export default router;
