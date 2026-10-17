import { Router } from 'express';
import { PlanController } from '../controllers/planController';
import { authMiddleware } from '../middlewares/authMiddleware';
import { validateRequest } from '../middlewares/zodValidator';
import { createPlanSchema, updatePlanSchema } from '../models/plan.model';

const router = Router();

router.use(authMiddleware);

// POST /api/plans - Create master budget for a month
router.post('/', validateRequest(createPlanSchema, 'body'), PlanController.createPlan);

// GET /api/plans/current - Retrieve active plan for current month
router.get('/current', PlanController.getCurrentPlan);

// PUT /api/plans/current - Update items in the master plan
router.put('/current', validateRequest(updatePlanSchema, 'body'), PlanController.updateCurrentPlan);

export default router;
