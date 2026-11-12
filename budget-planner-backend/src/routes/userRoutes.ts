import { Router } from 'express';
import { UserController } from '../controllers/userController';
import { authMiddleware } from '../middlewares/authMiddleware';
import { validateRequest } from '../middlewares/zodValidator';
import { syncUserSchema } from '../models/user.model';

const router = Router();

router.use(authMiddleware);

// GET /api/users/profile - Get current user profile
router.get('/profile', UserController.getProfile);

// POST /api/users/sync - Upsert user profile & save FCM token
router.post('/sync', validateRequest(syncUserSchema, 'body'), UserController.syncUser);

export default router;
