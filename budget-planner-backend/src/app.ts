import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import routes from './routes';
import { errorHandler } from './middlewares/errorHandler';
import { HTTP_STATUS } from './constants/statusCodes';

const app = express();

// Global Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check Route
app.get('/health', (req: Request, res: Response) => {
  res.status(HTTP_STATUS.OK).json({
    success: true,
    message: 'Budget Planner API service is operational',
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use('/api', routes);

// 404 Route Handler
app.use((req: Request, res: Response) => {
  res.status(HTTP_STATUS.NOT_FOUND).json({
    success: false,
    message: `Route ${req.method} ${req.originalUrl} not found`,
  });
});

// Global Error Handler
app.use(errorHandler);

export default app;
