import { Router } from 'express';
import { UserController } from '../controllers/userController';
import { authMiddleware } from '../middlewares/authMiddleware';
import { validateRequest } from '../middlewares/zodValidator';
import { syncUserSchema } from '../models/user.model';

const router = Router();

router.use(authMiddleware);

// POST /api/users/sync - Upsert user profile & save FCM token
router.post('/sync', validateRequest(syncUserSchema, 'body'), UserController.syncUser);

export default router;
