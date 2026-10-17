# Budget Planner Backend API

A production-ready, modular RESTful API backend for **Budget Planner** — a proactive personal finance app built with **Node.js**, **TypeScript**, **Express.js**, **Firebase Admin SDK** (Firestore, Firebase Auth, Firebase Cloud Messaging), **Zod**, and **node-cron**.

---

## 🛠 Project Architecture & Stack

- **Language & Runtime**: Node.js & TypeScript
- **Framework**: Express.js
- **Database & Services**: Firebase Admin SDK (Firestore, Auth, Cloud Messaging)
- **Validation**: Zod
- **Scheduled Tasks**: node-cron (Vietnam Timezone: Asia/Ho_Chi_Minh)
- **Layered Architecture**:
  ```text
  src/
  ├── config/        # Firebase Admin SDK & env validation
  ├── constants/     # HTTP status codes & response messages
  ├── controllers/   # Express request handlers & response formatting
  ├── jobs/          # Daily 21:00 node-cron job for FCM notifications
  ├── middlewares/   # Auth (verifyIdToken), Zod validator, error handler
  ├── models/        # TypeScript interfaces & Zod validation schemas
  ├── routes/        # API endpoints routing
  ├── services/      # Business logic & atomic Firestore transactions
  ├── app.ts         # Express application configuration
  └── server.ts      # Application entrypoint & cron initialization
  ```

---

## 🔑 Firebase Service Account & Setup Instructions

### 1. Download Service Account Key
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Select your project and navigate to **Project Settings > Service Accounts**.
3. Click **Generate New Private Key** to download the JSON key file.
4. Save this file into the root of this project as `serviceAccountKey.json`.

### 2. Configure `.env` File
Create a `.env` file in the root directory (or copy from `.env.example`):

```bash
# Server Port
PORT=5000
NODE_ENV=development

# Option A: Path to service account key file (Recommended for local dev)
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json

# Option B: Direct Environment Variables (Recommended for production deployments like Render/Heroku/Vercel)
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-firebase-project-id.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n"

# Set DEV_AUTH_BYPASS=true to test API locally without requiring live Firebase Auth headers
DEV_AUTH_BYPASS=false
```

---

## 🚀 Installation & Running

### Install Dependencies
```bash
npm install
```

### Run in Development Mode
```bash
npm run dev
```

### Build for Production
```bash
npm run build
npm start
```

---

## 🗄 Firestore Database Schema

### 1. `users` Collection
Document ID: `${userId}` (Firebase Auth UID)
```json
{
  "id": "uid_12345",
  "email": "user@example.com",
  "displayName": "John Doe",
  "fcmToken": "fcm_token_string",
  "createdAt": "2026-09-30T09:00:00.000Z",
  "updatedAt": "2026-09-30T09:00:00.000Z"
}
```

### 2. `monthly_plans` Collection
Document ID: `${userId}_${YYYY}_${MM}` (e.g., `uid_12345_2026_09`)
```json
{
  "id": "uid_12345_2026_09",
  "userId": "uid_12345",
  "month": 9,
  "year": 2026,
  "totalPlanned": 4500000,
  "actualSpent": 150000,
  "savedAmount": 4350000,
  "isLocked": false,
  "dailyRoutines": [
    { "id": "r1", "name": "Breakfast", "amount": 30000 }
  ],
  "weeklyRoutines": [
    { "id": "w1", "name": "Coffee with friends", "amount": 50000, "frequencyPerWeek": 2 }
  ],
  "monthlyFixed": [
    { "id": "m1", "name": "Internet bill", "amount": 250000 }
  ],
  "createdAt": "2026-09-01T00:00:00.000Z",
  "updatedAt": "2026-09-30T09:00:00.000Z"
}
```

### 3. `daily_logs` Collection
Document ID: `${userId}_${YYYY}_${MM}_${DD}` (e.g., `uid_12345_2026_09_30`)
```json
{
  "id": "uid_12345_2026_09_30",
  "userId": "uid_12345",
  "date": "2026-09-30",
  "items": [
    {
      "id": "item_1",
      "routineId": "r1",
      "name": "Breakfast",
      "amount": 30000,
      "type": "daily",
      "status": "completed"
    },
    {
      "id": "item_2",
      "routineId": "w1",
      "name": "Coffee with friends",
      "amount": 50000,
      "type": "weekly",
      "status": "skipped"
    }
  ],
  "unexpectedExpenses": [
    {
      "id": "exp_1",
      "amount": 120000,
      "reason": "Taxi fee during rainy day",
      "createdAt": "2026-09-30T14:30:00.000Z"
    }
  ],
  "createdAt": "2026-09-30T00:00:00.000Z",
  "updatedAt": "2026-09-30T14:30:00.000Z"
}
```

---

## 📡 API Endpoints Specification

All endpoints require Firebase Bearer token authentication in header:
`Authorization: Bearer <FIREBASE_ID_TOKEN>`

*(If `DEV_AUTH_BYPASS=true` is set in `.env`, you can pass optional `x-dev-user-id` header).*

### 1. Auth & User Profile
- **`POST /api/users/sync`**
  - **Body**:
    ```json
    {
      "email": "user@example.com",
      "displayName": "John Doe",
      "fcmToken": "fcm_token_device_abc"
    }
    ```

### 2. Monthly Master Plan (Budget Setup)
- **`POST /api/plans`**
  - **Body**:
    ```json
    {
      "month": 9,
      "year": 2026,
      "dailyRoutines": [
        { "name": "Breakfast", "amount": 30000 }
      ],
      "weeklyRoutines": [
        { "name": "Coffee", "amount": 50000, "frequencyPerWeek": 2 }
      ],
      "monthlyFixed": [
        { "name": "Internet", "amount": 250000 }
      ]
    }
    ```
- **`GET /api/plans/current?month=9&year=2026`**
- **`PUT /api/plans/current`**

### 3. Daily Check-in Interaction
- **`GET /api/daily/today?date=2026-09-30`**
  - Auto-populates daily routines if record for today doesn't exist yet.
- **`PATCH /api/daily/check-in`**
  - **Body**:
    ```json
    {
      "itemId": "item_1",
      "status": "skipped"
    }
    ```
  - **Atomic Firestore Transaction**:
    - Marks item status as `'skipped'` or `'completed'`.
    - Automatically updates `monthly_plans.savedAmount` and `monthly_plans.actualSpent`.
- **`POST /api/daily/unexpected-expense`**
  - **Body**:
    ```json
    {
      "amount": 120000,
      "reason": "Vehicle maintenance"
    }
    ```

### 4. Statistics & Reports
- **`GET /api/reports/monthly?month=9&year=2026`**
  - Returns `totalPlanned`, `actualSpent`, `savedAmount`, `skippedItemsInsights`, and `topUnexpectedExpenses`.
- **`GET /api/reports/history?month=9&year=2026`**
  - Returns daily breakdown timeline logs.

---

## ⏰ Background Jobs & FCM Notifications

A `node-cron` task runs daily at **21:00 (Asia/Ho_Chi_Minh)**:
- Queries users with pending check-in items for today.
- Sends batch push notifications using `firebase-admin.messaging()`.
- Title: `"Check-in chi tiêu hôm nay!"`
- Body: `"Chỉ mất 3 giây để tích chọn các khoản chi tiêu và cập nhật heo đất tiết kiệm nhé!"`
