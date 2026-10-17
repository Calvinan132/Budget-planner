import { Router } from 'express';
import userRoutes from './userRoutes';
import planRoutes from './planRoutes';
import dailyRoutes from './dailyRoutes';
import reportRoutes from './reportRoutes';

const router = Router();

router.use('/users', userRoutes);
router.use('/plans', planRoutes);
router.use('/daily', dailyRoutes);
router.use('/reports', reportRoutes);

export default router;
