# Budget Planner - System Workflow and Business Logic Specification
*(Triết lý: Lập lịch trước - Tích chọn sau)*

### 🔄 1. LIFECYCLE PHASES OF THE APP

The app operates strictly on a continuous 4-phase monthly loop:
[Phase 1: Master Setup] -> [Phase 2: Daily Generation & Check-in] -> [Phase 3: Real-Time Mutation] -> [Phase 4: Monthly Consolidation & Reporting]

---

### ⚙️️ 2. DETAILED PHASE WORKFLOW & SYSTEM LOGIC

#### PHASE 1: Master Plan Initialization (Beginning of Month / Day 1)
- Trigger: User opens the app for the first time or starts a new month without an active plan.
- User Action:
  1. Enters "Chi phí Hàng ngày" (e.g., Ăn sáng: 20k, Ăn trưa: 40k).
  2. Enters "Chi phí Hàng tuần" with a frequency indicator (e.g., Đổ xăng: 50k, 1 lần/tuần).
  3. Enters "Chi phí Hàng tháng (Cố định)" (e.g., Tiền trọ: 2.000k).
- Backend & State Processing:
  - System calculates:
    Total_Planned = (Sum(daily.amount) * DaysInMonth) 
                  + (Sum(weekly.amount * frequencyPerWeek * ~4.3)) 
                  + Sum(monthlyFixed.amount)
  - Sets initial state:
    - `totalPlanned` = Total_Planned
    - `actualSpent` = Total_Planned  // Assumed full spend baseline
    - `savedAmount` = 0
    - `isLocked` = true
  - Creates document in `monthly_plans`.

---

#### PHASE 2: Daily Schedule Generation (Everyday at 00:00 or On-First-Launch of the Day)
- Trigger: User opens the Home Screen or a daily cron triggers.
- System Processing:
  - Check if `daily_logs` exists for today (`userUid_YYYY_MM_DD`).
  - If NOT exists:
    - Auto-populate items:
      * ALL items from `dailyRoutines` with initial status: `pending`.
      * Eligible items from `weeklyRoutines` that have remaining unspent quota for the current week.
    - Save new `daily_logs` document.
  - Return the item list to the Flutter client.

---

#### PHASE 3: Daily Micro-Interactions & Real-Time State Mutation
Users interact via two main entry points on the Home Screen:

1. Interaction on Scheduled Items (Expandable Card):
   - User taps a card -> Card expands showing [Có tiêu] and [Không tiêu].
   - If User taps [Có tiêu] (`status = completed`):
     * Expense was already part of the baseline budget.
     * System marks item as `completed`.
     * `actualSpent` and `savedAmount` remain unchanged.
     * UI Action: Card triggers smooth slide/fade animation and completely disappears from the screen.
   - If User taps [Không tiêu] (`status = skipped`):
     * System marks item as `skipped`.
     * ATOMIC FIRESTORE TRANSACTION:
       - `monthly_plans.actualSpent -= item.amount`
       - `monthly_plans.savedAmount += item.amount`
     * UI Action: Card smoothly animates and disappears. The top live piggy bank counter instantly increments: `+item.amount`.

2. Interaction for Unexpected Out-of-Plan Expenses (FAB [+] Button):
   - User taps Floating Action Button -> Opens Bottom Sheet.
   - User enters `amount` and `reason` (e.g., 100k, Sửa xe) -> Submits.
   - ATOMIC FIRESTORE TRANSACTION:
     - Push new entry into `daily_logs.unexpectedExpenses`.
     - `monthly_plans.actualSpent += amount`
     - If (`actualSpent > totalPlanned`), update budget progress bar to warning state (Coral Red).
   - Bottom Sheet dismisses; live balance updates immediately.

---

#### PHASE 4: Daily Reminder & Nightly Push Notification
- Cron Schedule: Every day at 21:00 (Asia/Ho_Chi_Minh).
- Trigger Condition: Query all users who still have items with `status == pending` in today's `daily_logs`.
- Action:
  - Send batch push notification via FCM:
    * Title: "Check-in chi tiêu hôm nay!"
    * Body: "Chỉ mất 3 giây để xác nhận các khoản chi tiêu và cập nhật heo đất tiết kiệm nhé!"
- Midnight Handling: Any items left `pending` by 23:59:59 are automatically converted to `completed` by default (assuming spent) to prevent distortion of physical cash totals.

---

#### PHASE 5: Monthly Consolidation, Evaluation & Reporting (End of Month)
- Trigger: Accessed anytime via "Báo cáo cuối tháng" or triggered on the last day of the month.
- Data Aggregation:
  - Metrics:
    * `Ngân sách dự kiến gốc`: `monthly_plans.totalPlanned`
    * `Chi tiêu thực tế`: `monthly_plans.actualSpent`
    * `Tổng tiền tiết kiệm`: `monthly_plans.savedAmount`
  - Progress Bar Calculation:
    * Ratio = `actualSpent` / `totalPlanned`
    * If Ratio <= 1.0: Status is "Tiết kiệm / Trong tầm kiểm soát" (Emerald Green bar).
    * If Ratio > 1.0: Status is "Vượt mức ngân sách" (Coral Red bar).
  - Behavioral Analytics:
    * Scan all `daily_logs` of the month:
      - Count occurrences of `status == 'skipped'` grouped by routine name (e.g., "Bạn đã bỏ ăn sáng 5 lần trong tháng").
      - Sum total unexpected expenses and identify the biggest unexpected single item.
  - History Timeline Mapping:
    * Output chronological feed of every date with tagged visual indicators:
      - [Green Check]: Planned & Spent (`completed`)
      - [Gray/Red Strike]: Planned & Skipped (`skipped` / Saved money)
      - [Orange Plus]: Unexpected Expense (`unexpected`)

---

### 🛡️ 3. CORE SYSTEM INVARIANTS & INTEGRATION RULES
1. **Mathematical Accuracy**: Always maintain:
   `actualSpent = (totalPlanned - savedAmount) + sum(unexpectedExpenses)`.
2. **Idempotency**: A user tapping an item check-in multiple times rapidly must NOT double-decrement `actualSpent`. Status transitions must be guarded: only allow transitions from `pending` -> `completed` or `pending` -> `skipped`.
3. **Optimistic UI Updates**: The Flutter UI must instantly remove cards and update the local Piggy Bank counter upon tap, rolling back with a SnackBar error only if the backend returns a failure.
