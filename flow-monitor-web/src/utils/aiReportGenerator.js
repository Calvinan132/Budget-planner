// Map các Node ID với các file mã nguồn tương ứng trong dự án để AI biết chính xác vị trí cần sửa
export const nodeSourceFileMap = {
  // Backend API Nodes
  'backend_health': {
    service: 'Backend API Gateway',
    files: [
      'budget-planner-backend/src/app.ts',
      'budget-planner-backend/src/server.ts'
    ],
    hint: 'Kiểm tra port lắng nghe, CORS cấu hình, hoặc middleware trong app.ts'
  },
  'backend_users': {
    service: 'Users Service',
    files: [
      'budget-planner-backend/src/routes/userRoutes.ts',
      'budget-planner-backend/src/controllers/userController.ts',
      'budget-planner-backend/src/services/userService.ts',
      'budget-planner-backend/src/models/user.model.ts'
    ],
    hint: 'Kiểm tra logic xử lý user profile, token auth và validation Zod schema'
  },
  'backend_plans': {
    service: 'Monthly Plans Service',
    files: [
      'budget-planner-backend/src/routes/planRoutes.ts',
      'budget-planner-backend/src/controllers/planController.ts',
      'budget-planner-backend/src/services/planService.ts',
      'budget-planner-backend/src/models/plan.model.ts'
    ],
    hint: 'Kiểm tra logic tính toán hạn mức, tạo tháng mới và Firestore query'
  },
  'backend_daily': {
    service: 'Daily Logs Service',
    files: [
      'budget-planner-backend/src/routes/dailyRoutes.ts',
      'budget-planner-backend/src/controllers/dailyLogController.ts',
      'budget-planner-backend/src/services/dailyLogService.ts',
      'budget-planner-backend/src/models/dailyLog.model.ts'
    ],
    hint: 'Kiểm tra Firestore transaction ghi chép chi tiêu và trừ số dư kế hoạch'
  },
  'backend_reports': {
    service: 'Financial Reports Service',
    files: [
      'budget-planner-backend/src/routes/reportRoutes.ts',
      'budget-planner-backend/src/controllers/reportController.ts',
      'budget-planner-backend/src/services/reportService.ts',
      'budget-planner-backend/src/models/report.model.ts'
    ],
    hint: 'Kiểm tra thuật toán tổng hợp số liệu chi tiêu thực tế và tính phần trăm ngân sách'
  },

  // Flutter Client Nodes
  'client_app_init': {
    service: 'Flutter App Bootstrap',
    files: [
      'budget-planner-app/lib/main.dart',
      'budget-planner-app/lib/core/services/firebase_flow_tracker.dart'
    ],
    hint: 'Kiểm tra Firebase.initializeApp() và cấu hình theme/provider'
  },
  'client_login': {
    service: 'Flutter Auth Flow',
    files: [
      'budget-planner-app/lib/features/auth/screens/login_screen.dart',
      'budget-planner-app/lib/features/auth/services/auth_service.dart',
      'budget-planner-app/lib/core/network/auth_interceptor.dart'
    ],
    hint: 'Kiểm tra Firebase Auth token, Dio interceptor gắn Authorization header'
  },
  'client_monthly_plan': {
    service: 'Flutter Monthly Budget Screen',
    files: [
      'budget-planner-app/lib/features/budget_setup/screens/budget_setup_screen.dart',
      'budget-planner-app/lib/features/budget_setup/services/budget_plan_service.dart'
    ],
    hint: 'Kiểm tra parser BudgetPlanModel và state management Riverpod'
  },
  'client_add_expense': {
    service: 'Flutter Daily Check-in & Expense Entry',
    files: [
      'budget-planner-app/lib/features/daily_checkin/screens/daily_checkin_screen.dart',
      'budget-planner-app/lib/features/daily_checkin/controllers/daily_checkin_controller.dart'
    ],
    hint: 'Kiểm tra form validation và phương thức gửi khoản chi unexpected-expense'
  },
  'client_view_reports': {
    service: 'Flutter Financial Reports Screen',
    files: [
      'budget-planner-app/lib/features/reports/screens/reports_screen.dart',
      'budget-planner-app/lib/features/reports/controllers/report_controller.dart'
    ],
    hint: 'Kiểm tra biểu đồ vẽ báo cáo và xử lý dữ liệu rỗng (null safety)'
  },

  // Cloud & Cron
  'firebase_firestore_db': {
    service: 'Cloud Firestore Database',
    files: [
      'budget-planner-backend/firestore.rules',
      'budget-planner-backend/src/config/firebase.ts'
    ],
    hint: 'Kiểm tra quyền truy cập Security Rules hoặc kết nối Service Account Key'
  },
  'backend_cron_job': {
    service: 'Notification Cron Scheduler',
    files: [
      'budget-planner-backend/src/jobs/notificationJob.ts'
    ],
    hint: 'Kiểm tra cú pháp node-cron và hàm gửi FCM multicast message'
  }
};

/**
 * Tạo nội dung tệp Markdown chuẩn hóa để AI (Antigravity, Claude, Cursor) đọc và sửa chính xác
 */
export function generateAiFixReport(incident) {
  const {
    nodeId,
    label,
    status = 'DOWN',
    latencyMs = 0,
    statusCode = null,
    message = 'Lỗi không xác định',
    details = null,
    testedAt = new Date().toISOString()
  } = incident;

  const mapping = nodeSourceFileMap[nodeId] || {
    service: label || nodeId,
    files: ['Chưa xác định - xem chi tiết endpoint'],
    hint: 'Kiểm tra endpoint tương ứng'
  };

  const isDegraded = status === 'degraded';
  const severityTag = isDegraded ? '🟡 [PERFORMANCE DEGRADED]' : '🔴 [CRITICAL INCIDENT / DOWN]';

  return `# ${severityTag}: Sự Cố Tính Năng "${label || nodeId}"

> **Tự động tạo bởi:** Budget Planner Visual Flow Monitoring System  
> **Thời gian phát hiện:** ${testedAt}  
> **Trạng thái:** \`${status.toUpperCase()}\`  
> **Độ trễ:** \`${latencyMs}ms\` | **Mã HTTP:** \`${statusCode || 'N/A'}\`

---

## 1. Tóm Tắt Sự Cố & Thông Báo Lỗi
- **Mã Node gặp sự cố:** \`${nodeId}\`
- **Tính năng ảnh hưởng:** **${label || nodeId}**
- **Thông điệp lỗi ghi nhận:**
\`\`\`text
${message}
\`\`\`

${details ? `### Chi Tiết Kỹ Thuật (Payload / Stack Trace):
\`\`\`json
${JSON.stringify(details, null, 2)}
\`\`\`
` : ''}

---

## 2. Vị Trí File Mã Nguồn Cần Kiểm Tra & Sửa Lỗi
AI Agent vui lòng đọc và kiểm tra các tệp sau trong workspace của dự án:
${mapping.files.map(f => `- [${f}](file:///${f})`).join('\n')}

> **Gợi ý kiểm tra:** ${mapping.hint}

---

## 3. Lệnh Tái Hiện Lỗi (Reproduce Command)
Bạn có thể chạy thử lệnh curl sau trong terminal để kiểm tra phản hồi từ service:
\`\`\`bash
curl -i -X GET "http://localhost:5001${incident.targetEndpoint || '/health'}" \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer dev_bypass_token"
\`\`\`

---

## 4. Hướng Dẫn Yêu Cầu AI Khắc Phục (Action Plan for AI)
1. **Phân tích:** Đọc file mã nguồn nêu ở Mục 2 để tìm hiểu tại sao Node \`${nodeId}\` lại trả về lỗi trên.
2. **Khắc phục:** Sửa logic code, kiểm tra trường hợp dữ liệu rỗng (null-safety), hoặc chỉnh sửa cấu hình kết nối.
3. **Kiểm tra lại:** Chạy lại endpoint trên Backend hoặc bấm nút "Kiểm Tra Ngay" trên Website Monitor để xác nhận Node đã chuyển sang màu **Xanh (HEALTHY 🟢)**.
`;
}

/**
 * Kích hoạt tải tệp Markdown về máy
 */
export function downloadMarkdownFile(filename, content) {
  const blob = new Blob([content], { type: 'text/markdown;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.setAttribute('download', filename);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

/**
 * Sao chép nội dung vào Clipboard
 */
export async function copyToClipboard(text) {
  if (navigator.clipboard && window.isSecureContext) {
    await navigator.clipboard.writeText(text);
  } else {
    const textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.left = '-999999px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    document.execCommand('copy');
    textArea.remove();
  }
}

