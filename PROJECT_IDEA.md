# 📋 Budget Planner – Ý tưởng & Tổng quan dự án

> Dự án quản lý tài chính cá nhân theo mô hình **"Lập lịch trước – Tích chọn sau"** (Plan-first, Check-in later).  
> Người dùng lên kế hoạch chi tiêu tháng, sau đó hàng ngày tích chọn các khoản đã lên sẵn hoặc ghi chi tiêu phát sinh, ứng dụng tự động tính toán số tiền tiết kiệm và đưa ra báo cáo cuối tháng.

---

## 1. Mô tả tổng quan

**Budget Planner** là ứng dụng chi tiêu cá nhân giúp người dùng kiểm soát ngân sách hàng tháng một cách chủ động thay vì phản ứng sau khi chi tiêu.  
Ứng dụng chia ra hai phần:

- **Frontend:** Flutter (Android + iOS), sử dụng Riverpod quản lý trạng thái, Dio gọi API, Firebase Auth + Google Sign-In, lưu cache cục bộ cho chế độ offline.
- **Backend:** Node.js + TypeScript + Express, lưu dữ liệu trên **Firebase Firestore**, có cơ chế fallback in-memory khi mạng lỗi, bảo vệ bằng Firestore Security Rules.

---

## 2. Khái niệm cốt lõi

| Khái niệm                              | Ý nghĩa                                                                                                           |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Master Plan (Kế hoạch chính)**       | Danh sách các khoản chi định sẵn cho tháng: hàng ngày, hàng tuần, hàng tháng (cố định). Được tạo lúc đầu tháng.   |
| **Daily Log (Nhật ký ngày)**           | Mỗi ngày tạo một bản ghi chứa các món chi cần check-in (pending/completed/skipped) và chi tiêu phát sinh.         |
| **Piggy Bank (Heo tiết kiệm)**         | Số tiền được cộng vào khi người dùng chọn "Không tiêu" (skipped) cho một khoản đã lên kế hoạch.                   |
| **Unexpected Expense (Chi phát sinh)** | Chi tiêu không trong kế hoạch, bị trừ trực tiếp từ ngân sách và có thể làm vượt mức (cảnh báo đỏ).                |
| **Monthly Report (Báo cáo tháng)**     | Tổng hợp ngân sách dự kiến, chi thực tế, tiết kiệm, tỷ lệ chi tiêu, hành vi bỏ qua và chi phí phát sinh lớn nhất. |

---

## 3. Chu trình hoạt động (4 Pha)

Dựa trên `SYSTEM_SPEC.md`, ứng dụng hoạt động theo vòng lặp tháng liên tục:

### Pha 1: Khởi tạo Kế hoạch chính (Master Plan)

- **Khi:** Ngày 1 của tháng hoặc khi mở app lần đầu mà chưa có kế hoạch tháng hiện tại.
- **Người dùng nhập:**
  - Chi phí hàng ngày (ví dụ: Ăn sáng 20k, Ăn trưa 40k).
  - Chi phí hàng tuần kèm tần suất (ví dụ: Đổ xăng 50k, 1 lần/tuần).
  - Chi phí hàng tháng cố định (ví dụ: Tiền nhà 3.500k, Điện nước 500k).
- **Hệ thống tính:**  
  `Tổng dự kiến = Σ(hàng ngày × số ngày tháng) + Σ(hàng tuần × tần suất × 4.33) + Σ(hàng tháng cố định)`
- Lưu vào Firestore collection `monthly_plans` với doc ID `{uid}_{năm}_{tháng}`.

### Pha 2: Tạo lịch check-in hàng ngày (Daily Generation)

- **Khi:** Hàng ngày 00:00 (cron) hoặc khi người dùng mở màn hình Home lần đầu trong ngày.
- Hệ thống kiểm tra `daily_logs` của ngày hôm nay:
  - Nếu chưa có → tự động tạo các mục check-in từ `dailyRoutines` (tất cả) và `weeklyRoutines` (nếu còn hạn trong tuần), trạng thái ban đầu là `pending`.

### Pha 3: Tương tác micro hàng ngày (Real-time Mutation)

Người dùng tương tác qua 2 điểm vào chính trên Home Screen:

1. **Tích chọn món chi đã lên kế hoạch** (Expandable Card):
   - **Có tiêu (completed):** Món biến mất khỏi màn hình, `actualSpent`/`savedAmount` không đổi.
   - **Không tiêu (skipped):** Giao dịch nguyên tử Firestore: `actualSpent -= amount`, `savedAmount += amount`; heo đất tăng ngay lập tức.

2. **Chi tiêu phát sinh** (FAB [+] → Bottom Sheet):
   - Nhập số tiền và lý do (ví dụ: 100k, Sửa xe).
   - Giao dịch nguyên tử: thêm vào `daily_logs.unexpectedExpenses`, `actualSpent += amount`.
   - Nếu `actualSpent > totalPlanned` → thanh tiến độ chuyển màu đỏ (cảnh báo vượt ngân sách).

### Pha 4: Báo cáo & Tổng kết cuối tháng

- Xem báo cáo cuối tháng: tổng dự kiến, chi thực tế, tiết kiệm, tỷ lệ chi tiêu,進度條 (xanh nếu <= 100%, đỏ nếu > 100%).
- Lịch sử chi tiêu theo ngày: mỗi ngày hiển thị biểu tượng trạng thái (xanh check = đã tiêu, xám strike = bỏ qua, cam plus = phát sinh).
- Thống kê hành vi: khoản nào bị bỏ qua nhiều lần, chi phí phát sinh lớn nhất.
  - Lưu vào Firestore collection `daily_logs` với doc ID `{uid}_{YYYY}_{MM}_{DD}`.

## 4. Kiến trúc kỹ thuật

### 4.1 Frontend (Flutter)

```
lib/
├── main.dart                      # Entry point, routing
├── core/
│   ├── constants/                 # api_endpoints, app_colors, app_text_styles
│   ├── network/                   # dio_client, auth_interceptor (x-dev-user-id + Bearer token)
│   ├── services/                  # notification_service, offline_cache_service
│   ├── theme/                     # app_theme
│   ├── utils/                     # currency_formatter, date_helper
│   └── widgets/                   # user_avatar (đồng bộ avatar trên mọi trang)
├── models/                        # budget_plan_model, daily_expense_model, report_model, user_model
└── features/
    ├── auth/                      # Đăng nhập, Google Sign-In, auto-login, sync user
    ├── budget_setup/              # Tạo & chỉnh sửa kế hoạch tháng (master plan)
    ├── daily_checkin/             # Home screen, check-in món chi, chi phát sinh, chọn ngày xem lịch sử
    ├── profile/                   # Thông tin tài khoản, đăng xuất
    └── reports/                   # Báo cáo tháng, lịch sử chi tiêu timeline
```

**Thư viện chính:** `flutter_riverpod`, `dio`, `flutter_secure_storage`, `shared_preferences`, `firebase_core`, `firebase_auth`, `google_sign_in`, `firebase_messaging`, `flutter_local_notifications`, `intl`, `google_fonts`.

### 4.2 Backend (Node.js + TypeScript + Firebase)

```
src/
├── app.ts, server.ts              # Khởi tạo Express server (port 5001)
├── config/
│   ├── env.ts                     # Biến môi trường (FIREBASE_SERVICE_ACCOUNT_PATH, DEV_AUTH_BYPASS...)
│   ├── firebase.ts                # Firebase Admin SDK init (serviceAccountKey.json)
│   └── inMemoryDb.ts              # Fallback in-memory khi Firestore lỗi
├── constants/                     # status_codes, messages
├── controllers/                   # planController, reportController, dailyLogController, userController
├── jobs/                          # notification_job (push 21:00 hàng ngày, midnight consolidation 23:59)
├── middlewares/                   # authMiddleware (DEV_AUTH_BYPASS / x-dev-user-id), errorHandler, zodValidator
├── models/                        # plan.model, dailyLog.model, report.model, user.model (Zod schemas)
├── routes/                        # planRoutes, reportRoutes, dailyRoutes, userRoutes, index
├── services/                      # planService, dailyLogService, reportService, userService
└── tests/
```

**Cơ sở dữ liệu:** Firebase Firestore (3 collection chính: `users`, `monthly_plans`, `daily_logs`).

**API Endpoints chính:**
| Method | Endpoint | Chức năng |
|--------|----------|-----------|
| POST | `/api/plans` | Tạo kế hoạch tháng |
| GET | `/api/plans/current` | Lấy kế hoạch tháng hiện tại |
| PUT | `/api/plans/current` | Chỉnh sửa kế hoạch (adjust plan) |

## 5. Quy tắc nghiệp vụ quan trọng (Invariants)

1. **Độ chính xác toán học:**  
   `actualSpent = (totalPlanned − savedAmount) + Σ(unexpectedExpenses)`

2. **Idempotency:** Chỉ cho phép chuyển trạng thái từ `pending` → `completed` hoặc `pending` → `skipped`. Tránh trừ tiền kép khi nhấn nhanh nhiều lần.

3. **Offline-first:** Các thao tác check-in hôm nay được lưu cục bộ (`offline_cache_service`) và đồng bộ lên server khi có mạng.

4. **Bảo mật:** Firestore Security Rules chỉ cho phép người dùng đọc/ghi tài liệu có `userId` khớp với `request.auth.uid`.

5. **Múi giờ:** Tất cả logic ngày tháng sử dụng múi giờ **Asia/Ho_Chi_Minh** (luxon).

---

## 6. Tính năng đã triển khai (dựa trên code thực tế)

- [x] Đăng nhập / Đăng ký email & Google Sign-In
- [x] Tự động đăng nhập lại (auto-login) từ secure storage
- [x] Đồng bộ avatar Google lên backend và hiển thị đồng bộ trên mọi trang (`UserAvatar` widget)
- [x] Tạo Kế hoạch tháng (daily / weekly / monthly fixed)
- [x] **Chỉnh sửa kế hoạch** mà không bị reset về mặc định (adjust plan)
- [x] Tự động tạo danh sách check-in hàng ngày từ kế hoạch
- [x] Check-in món chi: Đã tiêu / Bỏ qua / Chờ xử lý (cho phép hoàn tác nếu chọn nhầm)
- [x] Ghi chi tiêu phát sinh và hoàn tác xóa chi phát sinh
- [x] Chọn ngày bất kỳ để xem lịch sử chi tiêu (không chỉ hôm nay)
- [x] Báo cáo cuối tháng: ngân sách, chi thực tế, tiết kiệm, tỷ lệ chi tiêu, hành vi bỏ qua
- [x] Lịch sử chi tiêu timeline theo ngày với màu sắc trạng thái
- [x] Push notification nhắc check-in hàng ngày 21:00, chuyển pending→completed lúc 23:59
- [x] Cache cục bộ cho chế độ offline
- [x] Fallback in-memory backend khi Firestore không kết nối được

---

## 7. Cách chạy dự án

### Backend

```bash
cd budget-planner-backend
npm install
# Tạo file .env từ .env.example, cấu hình FIREBASE_SERVICE_ACCOUNT_PATH
npm run dev          # Chạy dev (tsx watch) tại http://localhost:5001
npm run build        # Build TypeScript
npm start            # Chạy production (node dist/server.js)
```

### Frontend (Flutter)

```bash
cd budget-planner-app
flutter pub get
flutter run          # Chạy trên emulator/thiết bị
```

> Lưu ý: Backend đang chạy ở `localhost:5001` trong môi trường dev. Flutter emulator Android cần truy cập `10.0.2.2:5001` thay vì `localhost`.

---

## 8. Hướng phát triển đề xuất

1. **Sửa lỗi đồng bộ userId giữa tạo plan và lấy plan:** Đảm bảo `AuthInterceptor` luôn gửi header `x-dev-user-id` cố định (hoặc dùng Firebase UID nhất quán) để tránh lỗi "No active plan found".
2. **Hoàn thiện báo cáo:** Backend `report_service.dart` trên Flutter hiện trả mock data khi lỗi mạng — cần kết nối thực với `/api/reports/*`.
3. **Thêm chỉnh sửa số tiền chi phát sinh:** Hiện chỉ xóa hoàn toàn, chưa cho sửa lại số tiền/lý do.
4. **Thêm mục tiêu tiết kiệm (savings goal) riêng biệt:** Hiện dùng `totalPlanned` làm mục tiêu.
5. **Xuất báo cáo PDF/Excel:** Dùng cho月末 kiểm tra tài chính.
6. **Multi-currency:** Hiện hard-coded VND qua `currency_formatter`.

---

## 9. Cấu trúc dữ liệu chính (Firestore)

### `monthly_plans/{uid}_{year}_{month}`

```json
{
  "id": "uid_2026_10",
  "userId": "uid",
  "month": 10,
  "year": 2026,
  "totalPlanned": 4220000,
  "actualSpent": 0,
  "savedAmount": 4220000,
  "isLocked": false,
  "dailyRoutines": [{ "id": "...", "name": "Ăn sáng", "amount": 20000 }],
  "weeklyRoutines": [
    {
      "id": "...",
      "name": "Đi siêu thị",
      "amount": 500000,
      "frequencyPerWeek": 1
    }
  ],
  "monthlyFixed": [{ "id": "...", "name": "Tiền nhà", "amount": 3500000 }],
  "createdAt": "ISO string",
  "updatedAt": "ISO string"
}
```

### `daily_logs/{uid}_{YYYY}_{MM}_{DD}`

```json
{
  "id": "uid_2026_10_17",
  "userId": "uid",
  "date": "2026-10-17",
  "items": [
    {
      "id": "...",
      "routineId": "...",
      "name": "Ăn sáng",
      "amount": 20000,
      "type": "daily",
      "status": "pending"
    }
  ],
  "unexpectedExpenses": [
    {
      "id": "...",
      "amount": 100000,
      "reason": "Sửa xe",
      "createdAt": "ISO string"
    }
  ],
  "createdAt": "ISO string",
  "updatedAt": "ISO string"
}
```

### `users/{uid}`

```json
{
  "id": "uid",
  "email": "user@gmail.com",
  "displayName": "Nguyen Van A",
  "photoUrl": "https://...google avatar...",
  "fcmToken": "...",
  "createdAt": "ISO string"
}
```

---

## 10. Tác giả & Giấy phép

Dự án được phát triển bởi nhóm Budget Planner. Mã nguồn sử dụng Flutter (frontend) và Node.js/TypeScript (backend), lưu trữ trên Firebase Firestore.
| POST | `/api/plans/clone-previous` | Sao chép kế hoạch từ tháng trước |
| GET | `/api/daily/today` | Lấy/check-in hôm nay (tự sinh nếu chưa có) |
| PATCH | `/api/daily/check-in` | Cập nhật trạng thái món chi (completed/skipped/pending) |
| POST | `/api/daily/unexpected-expense` | Ghi chi tiêu phát sinh |
| DELETE | `/api/daily/unexpected-expense/:id` | Hoàn tác xóa chi phát sinh |
| GET | `/api/reports/monthly` | Báo cáo tổng hợp tháng |
| GET | `/api/reports/history` | Lịch sử chi tiêu theo ngày |
| POST | `/api/users/sync` | Đồng bộ thông tin người dùng (avatar, email, tên...) |

---

## 11. Kết quả rà soát & sửa lỗi toàn codebase (2026-10-18)

> Phạm vi: `budget-planner-app` (Flutter) + `budget-planner-backend` (Node/TS).
> Đối chiếu: Flutter models ↔ Zod schemas, đường dẫn endpoint, tên field DTO, luồng userId, hàng đợi offline.

### 11.1 Bugs phát hiện & đã sửa

| #   | Vị trí                                  | Mô tả lỗi                                                                                                                                                                                        | Cách sửa                                                                                                                                                                 |
| --- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | `reports/report_service.dart`           | Lỗi mạng → trả **mock data** (6tr / 90% / "5 cốc cà phê"...) che mất lỗi thật                                                                                                                    | Bỏ toàn bộ mock; lỗi lan lên controller → banner "Không thể tải báo cáo" trên UI                                                                                         |
| 2   | `models/report_model.dart`              | Parse sai field: backend trả `totalPlanned` nhưng model đọc `originalBudget` → luôn hiện 6.000.000; `spendingPercentage`, `skippedCount`, `behaviorLogs` **không tồn tại** trong payload backend | Map `totalPlanned→originalBudget`; tự tính `% = actualSpent/totalPlanned`; dựng behaviorLogs từ `skippedItemsInsights` + `topUnexpectedExpenses`; bỏ mọi default giả lập |
| 3   | `report_service.getHistoryTimeline`     | Backend trả `{logs: DailyLog[]}` (Map) nhưng service ép `as List` → luôn lỗi → **timeline luôn hiển thị 3 mục bịa**                                                                              | Bung `logs[]` → items + unexpectedExpenses, sort giảm dần theo ngày                                                                                                      |
| 4   | `monthly_report_screen.dart`            | Fallback `?? 6000000 / 5400000 / 600000 / 90` hiển thị số không có thật                                                                                                                          | Đổi toàn bộ thành `?? 0` + thêm banner lỗi tải báo cáo                                                                                                                   |
| 5   | Backend routes                          | **Không có API sửa chi phát sinh** (chỉ DELETE)                                                                                                                                                  | Thêm `PUT /api/daily/unexpected-expense/:id` (route + controller + service; transaction & inMemory fallback; chỉ chỉnh delta `actualSpent`, clamp ≥ 0)                   |
| 6   | Flutter chi phát sinh                   | Mảng `unexpectedExpenses` bị bỏ qua → không hiện trên home, không sửa/xóa được                                                                                                                   | `getTodayData` merge vào danh sách; card unexpected có nút **Sửa** (sheet chế độ edit, tự hiện số tiền/lý do cũ) & **Xóa** (dialog xác nhận)                             |
| 7   | Offline queue                           | Action offline **không gửi `?date=`** → sync trễ sang ngày sau bị ghi nhầm vào "hôm nay"                                                                                                         | Queue lưu `date`; `syncPendingActions` gửi `?date=` cho check_in / unexpected / update / delete                                                                          |
| 8   | Thêm chi phát sinh ngày cũ              | `addUnexpectedExpense` luôn ghi vào hôm nay dù đang xem ngày khác                                                                                                                                | Nhận `date` từ `selectedDate` của controller (yêu cầu "xem/sửa lịch sử ngày cũ")                                                                                         |
| 9   | `daily_checkin_controller`              | Thiếu delta heo đất cho `completed→skipped` (backend có, app không) → heo đất lệch sau nhiều lần đổi trạng thái                                                                                  | Thêm `piggyDelta = +amount` cho nhánh này                                                                                                                                |
| 10  | `dailyLogService` (backend)             | Delta check-in sai: `pending→skipped` **trừ actualSpent** dù khoản chưa từng chi → actualSpent **âm**; `completed↔skipped` nhân **×2** sai bản chất                                              | Sửa cả nhánh transaction + inMemory fallback: actualSpent chỉ đổi khi liên quan "Có tiêu"; thêm clamp `Math.max(0, …)`                                                   |
| 11  | `dailyLogService` add/delete unexpected | Ghi đè `savedAmount = totalPlanned − actualSpent` → **reset heo đất** mỗi lần chi/xóa phát sinh; UI Flutter không hề đụng heo đất ở luồng này                                                    | Bỏ cập nhật `savedAmount`, chỉ ± `actualSpent` → đồng bộ hoàn toàn FE/BE                                                                                                 |
| 12  | `monthly_report_screen`                 | Avatar icon "người" cứng, không dùng ảnh Google (yêu cầu đồng bộ avatar mọi trang)                                                                                                               | Thay bằng widget chung `UserAvatar(photoUrl, displayName)` — nay cả 4 tab Home / Kế hoạch / Báo cáo / Profile đều dùng chung                                             |
| 13  | `daily_home_screen`                     | Tiêu đề "Danh sách chi tiêu hôm nay" dù đang xem ngày khác                                                                                                                                       | Đổi thành "Danh sách chi tiêu dd/MM" khi chọn ngày không phải hôm nay                                                                                                    |
| 14  | `monthly_report_screen`                 | Hardcode `'Tháng 10, 2023'`                                                                                                                                                                      | Động từ `report.month/year`                                                                                                                                              |
| 15  | `auth_interceptor.dart` (sửa trước đó)  | 404 "No active plan found" do userId không khớp (`dev_test_user_123` vs `dev_mobile_user_1`)                                                                                                     | Luôn gửi header `x-dev-user-id: dev_mobile_user_1`                                                                                                                       |

### 11.2 Phát hiện còn lại (chưa sửa — cần quyết định)

- **Mô hình heo đất (`savedAmount`)**: `createPlan` khởi tạo `saved = totalPlanned` → heo đất = 100% ngay đầu tháng; công thức delta hiện theo hướng "heo = tiền tích lũy từ các lần bỏ qua, chi phát sinh không ảnh hưởng" (đã đồng bộ FE/BE theo hướng này). Nếu muốn "heo = ngân sách còn lại" thì phải đổi cả `createPlan` + toàn bộ check-in delta → cần quyết định sản phẩm trước khi sửa.
- Backend items không có `category` → icon trên home mặc định "túi shopping"; có thể suy ra từ tên khoản chi (giống `MonthlyReportModel.iconTypeFor`).
- `DEV_AUTH_BYPASS=true` chỉ dành cho dev; production phải bật verify Firebase ID token thật.
- Báo cáo tháng chưa có offline cache (khác màn hình home) → khi offline hiển thị số 0 + banner lỗi; có thể bổ sung cache nếu muốn.
- 25 info còn lại chủ yếu `withOpacity` deprecated / `prefer_const` — cleanup dần, không ảnh hưởng vận hành.
- **Chưa làm** (theo mục 8): #4 mục tiêu tiết kiệm riêng, #5 xuất PDF/Excel, #6 multi-currency — scope lớn, cần lập kế hoạch riêng.

### 11.3 API bổ sung & Kết quả verify

- API mới: `PUT /api/daily/unexpected-expense/:expenseId?date=YYYY-MM-DD` — body `{ amount, reason }` (Zod `unexpectedExpenseSchema`).
- API mới: `GET /api/users/profile` — Lấy thông tin hồ sơ người dùng đăng nhập hiện tại.
- Backend: `npx tsc --noEmit` & `npm run build` → **exit 0** ✅
- Flutter: `flutter analyze` → **0 error, 0 warning** ✅

### 11.4 Đồng bộ User ID thực & Liên kết toàn diện dữ liệu (Mới hoàn thành)

1. **User ID thực (Dynamic User Identification):**
   - Sửa `AuthInterceptor`: Không còn hardcode cố định `dev_mobile_user_1`. Hệ thống đọc UID thực từ `FirebaseAuth.currentUser.uid` hoặc `user_id` trong secure storage và gửi cả header `x-user-id` và `x-dev-user-id`.
   - Sửa `authMiddleware` backend: Nhận diện `x-user-id` / `x-dev-user-id` gửi từ app thay vì bị gán chết `dev_test_user_123`.
2. **Lưu trữ phiên đăng nhập bền vững:**
   - Sửa `AuthService`: Tự động ghi lại `user_id` vào secure storage khi đăng nhập hoặc sync thành công. `checkAutoLogin()` dùng lại đúng `user_id` này để người dùng luôn giữ đúng dữ liệu Master Plan và Daily Logs.
3. **In-Memory Fallback cho User Service:**
   - Bổ sung `users` dictionary vào `inMemoryDb` và bọc Firestore calls trong `userService.ts` để app không bao giờ bị crash 500 khi mạng Firestore gián đoạn.
4. **Liên kết dữ liệu Master Plan thật trên UI:**
   - Sửa `PlanOverviewScreen`: Đã loại bỏ danh sách khoản chi tĩnh ("Ăn uống 300k, Thuê nhà 8tr..."), thay thế bằng danh sách thực tế từ `plan.dailyRoutines`, `plan.weeklyRoutines`, và `plan.monthlyFixed`.
5. **Kéo để làm mới (Pull-to-refresh) cho Báo cáo:**
   - Thêm `RefreshIndicator` trên `MonthlyReportScreen` để người dùng chủ động tải lại dữ liệu mới nhất từ backend.

