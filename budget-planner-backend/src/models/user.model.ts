import { z } from 'zod';

export interface UserProfile {
  id: string; // Firebase Auth UID
  email: string;
  displayName: string;
  fcmToken?: string;
  createdAt: string;
  updatedAt?: string;
}

export const syncUserSchema = z.object({
  email: z.string().email('Invalid email address').optional(),
  displayName: z.string().min(1, 'Display name cannot be empty').optional(),
  fcmToken: z.string().optional(),
});

export type SyncUserDTO = z.infer<typeof syncUserSchema>;
