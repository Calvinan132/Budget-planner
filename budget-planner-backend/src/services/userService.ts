import { db } from '../config/firebase';
import { SyncUserDTO, UserProfile } from '../models/user.model';

const USERS_COLLECTION = 'users';

export class UserService {
  public static async syncUserProfile(userId: string, data: SyncUserDTO): Promise<UserProfile> {
    const userRef = db.collection(USERS_COLLECTION).doc(userId);
    const doc = await userRef.get();

    const now = new Date().toISOString();

    if (!doc.exists) {
      const newUser: UserProfile = {
        id: userId,
        email: data.email || '',
        displayName: data.displayName || 'Budget Planner User',
        fcmToken: data.fcmToken || '',
        createdAt: now,
        updatedAt: now,
      };

      await userRef.set(newUser);
      return newUser;
    } else {
      const existingData = doc.data() as UserProfile;
      const updatedUser: UserProfile = {
        ...existingData,
        email: data.email ?? existingData.email,
        displayName: data.displayName ?? existingData.displayName,
        fcmToken: data.fcmToken ?? existingData.fcmToken,
        updatedAt: now,
      };

      await userRef.update({
        email: updatedUser.email,
        displayName: updatedUser.displayName,
        fcmToken: updatedUser.fcmToken,
        updatedAt: updatedUser.updatedAt,
      });

      return updatedUser;
    }
  }

  public static async getUserProfile(userId: string): Promise<UserProfile | null> {
    const doc = await db.collection(USERS_COLLECTION).doc(userId).get();
    if (!doc.exists) {
      return null;
    }
    return doc.data() as UserProfile;
  }
}
