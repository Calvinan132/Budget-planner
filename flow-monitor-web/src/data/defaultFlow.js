export const defaultFlowNodes = [
  // --- LAYER 1: FLUTTER CLIENT FLOW ---
  {
    id: 'client_app_init',
    type: 'statusNode',
    position: { x: 50, y: 50 },
    data: {
      label: 'Flutter App Init',
      category: 'client',
      sublabel: 'Mobile Frontend',
      description: 'Khởi tạo ứng dụng Flutter & kết nối Firebase Core',
      testType: 'client_sim',
      targetEndpoint: 'client:app_bootstrap'
    }
  },
  {
    id: 'client_login',
    type: 'statusNode',
    position: { x: 50, y: 190 },
    data: {
      label: 'Google/Email Auth Flow',
      category: 'client',
      sublabel: 'Mobile Auth Flow',
      description: 'Luồng xác thực người dùng trên ứng dụng di động',
      testType: 'client_sim',
      targetEndpoint: 'client:auth_flow'
    }
  },
  {
    id: 'client_monthly_plan',
    type: 'statusNode',
    position: { x: 50, y: 330 },
    data: {
      label: 'Kế Hoạch Tháng (UI)',
      category: 'client',
      sublabel: 'Mobile Dashboard',
      description: 'Màn hình hiển thị ngân sách và hạn mức chi tiêu tháng',
      testType: 'client_sim',
      targetEndpoint: 'client:monthly_plan_view'
    }
  },
  {
    id: 'client_add_expense',
    type: 'statusNode',
    position: { x: 50, y: 470 },
    data: {
      label: 'Thêm Chi Tiêu (UI)',
      category: 'client',
      sublabel: 'Mobile Entry Form',
      description: 'Màn hình nhập giao dịch chi tiêu hàng ngày',
      testType: 'client_sim',
      targetEndpoint: 'client:add_expense_view'
    }
  },
  {
    id: 'client_view_reports',
    type: 'statusNode',
    position: { x: 50, y: 610 },
    data: {
      label: 'Báo Cáo Chi Tiêu (UI)',
      category: 'client',
      sublabel: 'Mobile Analytics',
      description: 'Biểu đồ phân tích tài chính và xu hướng chi tiêu',
      testType: 'client_sim',
      targetEndpoint: 'client:reports_view'
    }
  },

  // --- LAYER 2: BACKEND NODE.JS REST APIS (PORT 5001) ---
  {
    id: 'backend_health',
    type: 'statusNode',
    position: { x: 420, y: 50 },
    data: {
      label: 'Backend Gateway Health',
      category: 'backend',
      sublabel: 'GET /health',
      description: 'Kiểm tra độ sẵn sàng của REST API Backend Express',
      testType: 'http_get',
      targetEndpoint: '/health'
    }
  },
  {
    id: 'backend_users',
    type: 'statusNode',
    position: { x: 420, y: 190 },
    data: {
      label: 'Users Service',
      category: 'backend',
      sublabel: '/api/users',
      description: 'Đăng ký và lấy thông tin hồ sơ tài chính người dùng',
      testType: 'http_get',
      targetEndpoint: '/api/users/profile'
    }
  },
  {
    id: 'backend_plans',
    type: 'statusNode',
    position: { x: 420, y: 330 },
    data: {
      label: 'Monthly Plans Service',
      category: 'backend',
      sublabel: '/api/plans',
      description: 'Quản lý hạn mức chi tiêu, danh mục và kế hoạch tháng',
      testType: 'http_get',
      targetEndpoint: '/api/plans/current'
    }
  },
  {
    id: 'backend_daily',
    type: 'statusNode',
    position: { x: 420, y: 470 },
    data: {
      label: 'Daily Logs Service',
      category: 'backend',
      sublabel: '/api/daily',
      description: 'Ghi nhận và tra cứu các khoản chi tiêu mỗi ngày',
      testType: 'http_get',
      targetEndpoint: '/api/daily/today'
    }
  },
  {
    id: 'backend_reports',
    type: 'statusNode',
    position: { x: 420, y: 610 },
    data: {
      label: 'Financial Reports Service',
      category: 'backend',
      sublabel: '/api/reports',
      description: 'Tổng hợp tính toán chi tiêu thực tế so với ngân sách',
      testType: 'http_get',
      targetEndpoint: '/api/reports/monthly'
    }
  },

  // --- LAYER 3: FIREBASE & BACKGROUND JOBS ---
  {
    id: 'firebase_auth_service',
    type: 'statusNode',
    position: { x: 800, y: 190 },
    data: {
      label: 'Firebase Auth',
      category: 'cloud',
      sublabel: 'Identity & Tokens',
      description: 'Quản lý xác thực tài khoản và cấp JWT ID Token',
      testType: 'firebase_auth',
      targetEndpoint: 'firebase:auth'
    }
  },
  {
    id: 'firebase_firestore_db',
    type: 'statusNode',
    position: { x: 800, y: 400 },
    data: {
      label: 'Cloud Firestore',
      category: 'cloud',
      sublabel: 'NoSQL Database',
      description: 'Lưu trữ users, monthly_plans, daily_logs, node_statuses',
      testType: 'firestore_ping',
      targetEndpoint: 'firestore:ping'
    }
  },
  {
    id: 'firebase_fcm',
    type: 'statusNode',
    position: { x: 800, y: 550 },
    data: {
      label: 'Firebase Cloud Messaging',
      category: 'cloud',
      sublabel: 'Push Notification',
      description: 'Gửi thông báo đẩy nhắc nhở ghi sổ chi tiêu vào 20:00',
      testType: 'fcm_ping',
      targetEndpoint: 'firebase:messaging'
    }
  },
  {
    id: 'backend_cron_job',
    type: 'statusNode',
    position: { x: 800, y: 700 },
    data: {
      label: 'Daily Notification Cron',
      category: 'cron',
      sublabel: 'Node-cron (20:00)',
      description: 'Tác vụ định kỳ kiểm tra user chưa ghi chép và kích hoạt FCM',
      testType: 'cron_status',
      targetEndpoint: 'cron:daily_reminder'
    }
  }
];

export const defaultFlowEdges = [
  // Client to Backend
  { id: 'e_init_health', source: 'client_app_init', target: 'backend_health', animated: true },
  { id: 'e_login_users', source: 'client_login', target: 'backend_users', animated: true },
  { id: 'e_plan_backend', source: 'client_monthly_plan', target: 'backend_plans', animated: true },
  { id: 'e_daily_backend', source: 'client_add_expense', target: 'backend_daily', animated: true },
  { id: 'e_report_backend', source: 'client_view_reports', target: 'backend_reports', animated: true },

  // Client directly to Firebase Auth
  { id: 'e_client_fbauth', source: 'client_login', target: 'firebase_auth_service', animated: true },

  // Backend to Firebase Services
  { id: 'e_users_auth', source: 'backend_users', target: 'firebase_auth_service', animated: true },
  { id: 'e_plans_db', source: 'backend_plans', target: 'firebase_firestore_db', animated: true },
  { id: 'e_daily_db', source: 'backend_daily', target: 'firebase_firestore_db', animated: true },
  { id: 'e_report_db', source: 'backend_reports', target: 'firebase_firestore_db', animated: true },

  // Cron to FCM & DB
  { id: 'e_cron_db', source: 'backend_cron_job', target: 'firebase_firestore_db', animated: true },
  { id: 'e_cron_fcm', source: 'backend_cron_job', target: 'firebase_fcm', animated: true },
  { id: 'e_fcm_client', source: 'firebase_fcm', target: 'client_add_expense', animated: true }
];

