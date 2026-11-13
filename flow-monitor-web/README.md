# 🌐 Visual Flow & Feature Health Monitor - Budget Planner

Hệ thống Website quản trị trực quan hóa luồng hoạt động (Visual Operational Flow) và kiểm tra sức khỏe tính năng thời gian thực (Real-time Feature Health Check) cho ứng dụng Budget Planner (Frontend: Flutter, Backend: Node.js/Express, Cloud: Firebase Firestore).

---

## 🚀 Tính Năng Chính

1. **Vẽ & Quản Lý Sơ Đồ Luồng (Visual Flow Builder - React Flow)**:
   - Kéo thả các Node đại diện cho từng tính năng: Flutter Client, Backend API, Firebase Cloud & Background Cron.
   - Nối dây (Edges) linh hoạt để thể hiện luồng nghiệp vụ end-to-end.
   - Thêm/Xóa/Sửa các Node tính năng mới thông qua giao diện trực quan.
   - Lưu cấu hình sơ đồ lên Firestore collection `flow_configs/main_flow` (kèm fallback LocalStorage).

2. **Kiểm Tra Tính Năng & Giám Sát Trạng Thái Thời Gian Thực**:
   - Nút **"Kiểm Tra Toàn Bộ Flow"**: Tự động chạy lần lượt qua tất cả các Node trên sơ đồ, gửi request kiểm tra và đo latency từng tính năng.
   - Nút **"Test"** trên từng Node: Kiểm thử nhanh một endpoint hoặc tính năng đơn lẻ (ví dụ: `GET /health`, `/api/plans`, `/api/daily`).
   - Hiển thị trực quan:
     - 🟢 **Healthy**: Hoạt động bình thường, phản hồi nhanh (< 500ms).
     - 🟡 **Degraded**: Cảnh báo độ trễ cao hoặc cần xác thực token.
     - 🔴 **Down**: Lỗi kết nối server, timeout hoặc mã lỗi HTTP 5xx. Dây nối chuyển sang nét đứt màu đỏ.
     - ⚪ **Idle**: Chưa kiểm tra.

3. **Drawer Tra Cứu Chi Tiết & Lịch Sử Lỗi (Inspector)**:
   - Click vào bất kỳ Node nào để mở Drawer bên phải.
   - Xem thông tin endpoint, mã HTTP status, độ trễ ms, và biểu đồ cột trực quan hóa độ trễ gần nhất.
   - Tra cứu danh sách lỗi chi tiết từ collection `node_logs` (tự động xóa sau 7 ngày theo chính sách TTL của Firestore).

---

## 🛠️ Hướng Dẫn Khởi Chạy

### 1. Khởi chạy Website Quản Trị
```bash
cd flow-monitor-web
npm install
npm run dev
```
Mở trình duyệt tại: `http://localhost:3000`

### 2. Cấu hình biến môi trường (`.env`)
Nếu muốn đồng bộ trực tiếp lên Cloud Firestore thay vì chế độ Local:
```env
VITE_FIREBASE_API_KEY="AIzaSy..."
VITE_FIREBASE_AUTH_DOMAIN="budget-planner-dev.firebaseapp.com"
VITE_FIREBASE_PROJECT_ID="budget-planner-dev"
VITE_FIREBASE_STORAGE_BUCKET="budget-planner-dev.appspot.com"
VITE_FIREBASE_MESSAGING_SENDER_ID="123456789"
VITE_FIREBASE_APP_ID="1:123456789:web:abcdef"

# URL Backend để thực hiện kiểm tra tính năng trực tiếp
VITE_BACKEND_API_URL="http://localhost:5001"
```
*(Nếu chưa điền API Key, hệ thống tự động hoạt động ở chế độ Local & Live Backend API ping mà không hề phát sinh lỗi)*.

---

## 🔄 Kết Nối Vào Backend & Mobile App

- **Backend Express**: Đã tích hợp middleware `flowMonitor('nodeId')` tại `budget-planner-backend/src/middlewares/flowMonitorMiddleware.ts`.
- **Flutter App**: Đã tích hợp helper `FirebaseFlowTracker` tại `budget-planner-app/lib/core/services/firebase_flow_tracker.dart`.
- **Firestore Security Rules**: Đã cập nhật file `firestore.rules` để cho phép đồng bộ `flow_configs`, `node_statuses`, và `node_logs`.

