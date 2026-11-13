# 🚀 Hướng Dẫn Tích Hợp & Vận Hành Hệ Thống Flow & Health Monitor

Toàn bộ hệ thống kiểm tra và giám sát luồng hoạt động trực quan đã được cài đặt vào thư mục dự án của bạn:

```
dev/
├── flow-monitor-web/                  # 🌐 Website React Flow quản trị & kiểm thử tính năng
│   ├── src/
│   │   ├── components/
│   │   │   ├── StatusNode.jsx         # Custom React Flow Node hiển thị ping & trạng thái
│   │   │   ├── NodeDetailDrawer.jsx   # Drawer tra cứu log, biểu đồ latency & kiểm thử
│   │   │   ├── AddNodeModal.jsx       # Modal thêm tính năng mới vào flow
│   │   │   └── TopNavbar.jsx          # Thanh công cụ & tổng quan trạng thái hệ thống
│   │   ├── data/
│   │   │   └── defaultFlow.js         # Sơ đồ mẫu kiến trúc đầy đủ của Budget Planner
│   │   ├── services/
│   │   │   └── healthCheckService.js  # Engine kiểm tra tính năng & đo latency
│   │   ├── firebase.js                # Firebase Web SDK & Fallback LocalStore
│   │   └── App.jsx                    # Canvas điều khiển chính
│   ├── .env                           # Cấu hình Firebase & Backend URL (port 5001)
│   └── package.json
│
├── budget-planner-backend/            # ⚙️ Node.js REST API Backend
│   ├── src/
│   │   ├── middlewares/
│   │   │   └── flowMonitorMiddleware.ts # Middleware đo latency & throttle gửi Firestore
│   │   ├── routes/index.ts            # Đã gắn flowMonitor vào từng endpoint nghiệp vụ
│   │   └── app.ts                     # Đã gắn flowMonitor vào /health
│   └── firestore.rules                # Đã cập nhật rules cho flow_configs, node_statuses, node_logs
│
└── budget-planner-app/                # 📱 Ứng dụng Flutter Mobile
    └── lib/core/services/
        └── firebase_flow_tracker.dart # Class helper đo đạc và báo cáo trạng thái luồng Client
```

---

## 🧭 Cách Chạy Và Kiểm Thử Tính Năng

### Bước 1: Khởi động Backend (Node.js)
```bash
cd budget-planner-backend
npm run dev
```
*(Backend sẽ lắng nghe tại `http://localhost:5001`)*

### Bước 2: Khởi động Website Quản Trị (React Flow)
```bash
cd flow-monitor-web
npm run dev
```
Mở trình duyệt tại: `http://localhost:3000`

### Bước 3: Trải nghiệm tính năng trên Website
1. **Kiểm tra sức khỏe tính năng:**
   - Bấm nút **"Kiểm Tra Toàn Bộ Flow"** trên thanh tiêu đề để hệ thống tự động quét qua tất cả các Node trên sơ đồ.
   - Bấm nút **"Test"** trực tiếp trên từng Node (ví dụ: `Backend Gateway Health`, `Monthly Plans Service`, `Daily Logs Service`).
   - Nếu Backend đang chạy: Node sẽ chuyển sang màu **Xanh (Healthy)** kèm chỉ số ping ms.
   - Nếu Backend chưa bật: Node sẽ lập tức chuyển sang màu **Đỏ (Down)** kèm thông báo lỗi và dây nối đổi thành nét đứt đỏ.
2. **Xem chi tiết & Logs:**
   - Click vào bất kỳ Node nào để mở Drawer kiểm tra log lỗi, thời gian và biểu đồ độ trễ.
3. **Thêm / Chỉnh sửa luồng:**
   - Bấm **"Thêm Tính Năng"** để thêm một Node nghiệp vụ mới.
   - Kéo các đầu chấm tròn trên Node để nối dây (Edge) giữa các tính năng.
   - Bấm **"Lưu Sơ Đồ"** để lưu lại trạng thái canvas.

