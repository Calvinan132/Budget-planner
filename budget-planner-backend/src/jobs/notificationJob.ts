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
  * Midnight Cron Job: Runs at 23:59:59 (Asia/Ho_Chi_Minh).
  * Automatically marks any lingering 'pending' items as 'completed' (assuming spent).
  */
export const autoResolvePendingDailyItems = async (): Promise<void> => {
  const todayStr = DateTime.now().setZone('Asia/Ho_Chi_Minh').toISODate()!;
  console.log(`[Midnight Job] Auto-resolving pending items for: ${todayStr}`);

  try {
    const logsSnapshot = await db.collection(DAILY_LOGS_COLLECTION).where('date', '==', todayStr).get();
    if (logsSnapshot.empty) return;

    let updatedCount = 0;
    const batch = db.batch();

    logsSnapshot.docs.forEach((doc) => {
      const log = doc.data() as DailyLog;
      let hasChange = false;

      log.items.forEach((item) => {
        if (item.status === 'pending') {
          item.status = 'completed'; // Mặc định đã tiêu nếu không tích bỏ qua
          hasChange = true;
          updatedCount++;
        }
      });

      if (hasChange) {
        log.updatedAt = new Date().toISOString();
        batch.set(doc.ref, log, { merge: true });
      }
    });

    if (updatedCount > 0) {
      await batch.commit();
      console.log(`[Midnight Job] Successfully auto-completed ${updatedCount} pending items.`);
    }
  } catch (error) {
    console.error('[Midnight Job] Error auto-resolving pending items:', error);
  }
};

/**
 * Initialize node-cron schedule for 21:00 and 23:59 (Asia/Ho_Chi_Minh)
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

  // Midnight consolidation: 59 23 * * * -> At 23:59 every day
  cron.schedule(
    '59 23 * * *',
    async () => {
      await autoResolvePendingDailyItems();
    },
    {
      timezone: 'Asia/Ho_Chi_Minh',
    }
  );

  console.log('[Cron Job] Registered 21:00 notification and 23:59 midnight consolidation jobs (Asia/Ho_Chi_Minh)');
  return task;
};

