import app from './app';
import { env } from './config/env';
import { initNotificationCronJob } from './jobs/notificationJob';

const startServer = (): void => {
  try {
    // Initialize background cron jobs
    initNotificationCronJob();

    // Start HTTP Server
    app.listen(env.PORT, () => {
      console.log(`================================================`);
      console.log(`🚀 Budget Planner REST API Backend`);
      console.log(`📡 Environment: ${env.NODE_ENV}`);
      console.log(`🌐 Server running at: http://localhost:${env.PORT}`);
      console.log(`================================================`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();
