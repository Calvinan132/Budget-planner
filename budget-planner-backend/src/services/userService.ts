import { db } from '../config/firebase';
import { inMemoryDb } from '../config/inMemoryDb';
import { SyncUserDTO, UserProfile } from '../models/user.model';

const USERS_COLLECTION = 'users';

export class UserService {
  public static async syncUserProfile(userId: string, data: SyncUserDTO): Promise<UserProfile> {
    const now = new Date().toISOString();

    try {
      const userRef = db.collection(USERS_COLLECTION).doc(userId);
      const doc = await userRef.get();

      if (!doc.exists) {
        const newUser: UserProfile = {
          id: userId,
          email: data.email || '',
          displayName: data.displayName || 'Budget Planner User',
          photoUrl: data.photoUrl || '',
          fcmToken: data.fcmToken || '',
          createdAt: now,
          updatedAt: now,
        };

        await userRef.set(newUser);
        inMemoryDb.users[userId] = newUser;
        return newUser;
      } else {
        const existingData = doc.data() as UserProfile;
        const updatedUser: UserProfile = {
          ...existingData,
          email: data.email ?? existingData.email,
          displayName: data.displayName ?? existingData.displayName,
          photoUrl: data.photoUrl ?? existingData.photoUrl,
          fcmToken: data.fcmToken ?? existingData.fcmToken,
          updatedAt: now,
        };

        await userRef.update({
          email: updatedUser.email,
          displayName: updatedUser.displayName,
          photoUrl: updatedUser.photoUrl,
          fcmToken: updatedUser.fcmToken,
          updatedAt: updatedUser.updatedAt,
        });

        inMemoryDb.users[userId] = updatedUser;
        return updatedUser;
      }
    } catch (error) {
      console.warn('[UserService] Firestore operation failed, falling back to inMemoryDb:', error);
      const existing = inMemoryDb.users[userId] as UserProfile | undefined;
      const user: UserProfile = {
        id: userId,
        email: data.email ?? existing?.email ?? '',
        displayName: data.displayName ?? existing?.displayName ?? 'Budget Planner User',
        photoUrl: data.photoUrl ?? existing?.photoUrl ?? '',
        fcmToken: data.fcmToken ?? existing?.fcmToken ?? '',
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      };
      inMemoryDb.users[userId] = user;
      return user;
    }
  }

  public static async getUserProfile(userId: string): Promise<UserProfile | null> {
    // ⚡ SHORT-CIRCUIT: Trả về ngay cho dev_user_monitor TRƯỚC khi gọi Firestore (tránh timeout 80s)
    if (userId === 'dev_user_monitor') {
      return inMemoryDb.users[userId] || {
        id: userId,
        email: 'dev_user_monitor@gmail.com',
        displayName: 'Flow Monitor User',
        photoUrl: '',
        fcmToken: '',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
    }

    // ⚡ SHORT-CIRCUIT: Có trong inMemoryDb rồi thì không cần gọi Firestore
    if (inMemoryDb.users[userId]) {
      return inMemoryDb.users[userId] as UserProfile;
    }

    try {
      const doc = await db.collection(USERS_COLLECTION).doc(userId).get();
      if (!doc.exists) {
        return null;
      }
      const profile = doc.data() as UserProfile;
      inMemoryDb.users[userId] = profile;
      return profile;
    } catch (error) {
      return inMemoryDb.users[userId] || null;
    }
  }
}
