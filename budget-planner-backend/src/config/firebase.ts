import * as admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { env } from './env';

let firebaseApp: admin.app.App;

const initFirebase = (): admin.app.App => {
  if (admin.apps.length > 0) {
    return admin.apps[0]!;
  }

  // 1. Try loading from service account JSON file path
  if (env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    const absolutePath = path.isAbsolute(env.FIREBASE_SERVICE_ACCOUNT_PATH)
      ? env.FIREBASE_SERVICE_ACCOUNT_PATH
      : path.join(process.cwd(), env.FIREBASE_SERVICE_ACCOUNT_PATH);

    if (fs.existsSync(absolutePath)) {
      try {
        const serviceAccount = JSON.parse(fs.readFileSync(absolutePath, 'utf8'));
        firebaseApp = admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
        console.log(`[Firebase] Initialized using service account file at ${absolutePath}`);
        return firebaseApp;
      } catch (err) {
        console.warn(`[Firebase] Failed to parse service account JSON file at ${absolutePath}:`, err);
      }
    }
  }

  // 2. Try loading from individual environment variables
  if (env.FIREBASE_PROJECT_ID && env.FIREBASE_CLIENT_EMAIL && env.FIREBASE_PRIVATE_KEY) {
    try {
      const privateKey = env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: env.FIREBASE_PROJECT_ID,
          clientEmail: env.FIREBASE_CLIENT_EMAIL,
          privateKey: privateKey,
        }),
      });
      console.log(`[Firebase] Initialized using environment variables for project "${env.FIREBASE_PROJECT_ID}"`);
      return firebaseApp;
    } catch (err) {
      console.warn('[Firebase] Failed to initialize with environment variables:', err);
    }
  }

  // 3. Fallback to default application credentials or emulator
  try {
    firebaseApp = admin.initializeApp();
    console.log('[Firebase] Initialized using default application credentials');
    return firebaseApp;
  } catch (err) {
    console.warn('[Firebase] Application credentials not found. Initializing with mock credential for dev mode.');
    firebaseApp = admin.initializeApp({
      projectId: env.FIREBASE_PROJECT_ID || 'budget-planner-dev',
    });
    return firebaseApp;
  }
};

firebaseApp = initFirebase();

export const db = firebaseApp.firestore();
export const auth = firebaseApp.auth();
export const messaging = firebaseApp.messaging();
export default firebaseApp;
