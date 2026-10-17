import cron from 'node-cron';
import { DateTime } from 'luxon';
import { db, messaging } from '../config/firebase';
import { DailyLog } from '../models/dailyLog.model';
import { UserProfile } from '../models/user.model';

const DAILY_LOGS_COLLECTION = 'daily_logs';
const USERS_COLLECTION = 'users';

/**
 * Execute the check-in push notification batch send logic
 */
export const sendCheckInPushNotifications = async (): Promise<void> => {
  const todayStr = DateTime.now().setZone('Asia/Ho_Chi_Minh').toISODate()!;
  console.log(`[Cron Job] Running daily 21:00 check-in notification job for date: ${todayStr}`);

  try {
    // 1. Fetch daily logs for today
    const logsSnapshot = await db.collection(DAILY_LOGS_COLLECTION).where('date', '==', todayStr).get();

    if (logsSnapshot.empty) {
      console.log('[Cron Job] No daily logs found for today.');
      return;
    }

    // 2. Identify users with pending items
    const pendingUserIds = new Set<string>();

    logsSnapshot.docs.forEach((doc) => {
      const log = doc.data() as DailyLog;
      const hasPendingItems = log.items.some((item) => item.status === 'pending');
      if (hasPendingItems) {
        pendingUserIds.add(log.userId);
      }
    });

    if (pendingUserIds.size === 0) {
      console.log('[Cron Job] All users have completed or skipped their check-in items today.');
      return;
    }

    // 3. Retrieve FCM tokens for pending users
    const fcmTokens: string[] = [];
    const userIdsArray = Array.from(pendingUserIds);

    // Chunk queries to handle Firestore "in" filter limit of 30 items
    const chunkSize = 30;
    for (let i = 0; i < userIdsArray.length; i += chunkSize) {
      const chunk = userIdsArray.slice(i, i + chunkSize);
      const usersSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('id', 'in', chunk)
        .get();

      usersSnapshot.docs.forEach((doc) => {
        const user = doc.data() as UserProfile;
        if (user.fcmToken && user.fcmToken.trim().length > 0) {
          fcmTokens.push(user.fcmToken);
        }
      });
    }

    if (fcmTokens.length === 0) {
      console.log('[Cron Job] Found pending users, but none have active FCM tokens stored.');
      return;
    }

    // 4. Send batch push notifications via Firebase Cloud Messaging
    const payload = {
      notification: {
        title: 'Check-in chi tiêu hôm nay!',
        body: 'Chỉ mất 3 giây để tích chọn các khoản chi tiêu và cập nhật heo đất tiết kiệm nhé!',
      },
      tokens: fcmTokens,
    };

    const response = await messaging.sendEachForMulticast(payload);

    console.log(
      `[Cron Job] Notification dispatch complete. Success: ${response.successCount}, Failures: ${response.failureCount}`
    );
  } catch (error) {
    console.error('[Cron Job] Error during push notification dispatch:', error);
  }
};

/**
 * Initialize node-cron schedule for 21:00 (Asia/Ho_Chi_Minh)
 */
export const initNotificationCronJob = (): cron.ScheduledTask => {
  // Cron expression: 0 21 * * * -> At 21:00 every day
  const task = cron.schedule(
    '0 21 * * *',
    async () => {
      await sendCheckInPushNotifications();
    },
    {
      timezone: 'Asia/Ho_Chi_Minh',
    }
  );

  console.log('[Cron Job] Registered daily notification job at 21:00 (Asia/Ho_Chi_Minh)');
  return task;
};
