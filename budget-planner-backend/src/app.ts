import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import fs from 'fs';
import path from 'path';
import routes from './routes';
import { errorHandler } from './middlewares/errorHandler';
import { HTTP_STATUS } from './constants/statusCodes';
import { flowMonitor } from './middlewares/flowMonitorMiddleware';

const app = express();

// Global Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check Route with Flow Monitoring
app.get('/health', flowMonitor('backend_health'), (req: Request, res: Response) => {
  res.status(HTTP_STATUS.OK).json({
    success: true,
    message: 'Budget Planner API service is operational',
    timestamp: new Date().toISOString(),
  });
});

// AI Incident Logging Endpoint: Ghi lại sự cố tính năng ra file FLOW_INCIDENTS.md để AI đọc và fix
app.post('/api/flow-monitor/incident', (req: Request, res: Response) => {
  const { nodeId, label, status, latencyMs, statusCode, message, details, targetEndpoint } = req.body;
  const timestamp = new Date().toISOString();
  const statusUpper = (status || 'DOWN').toUpperCase();
  const severityEmoji = statusUpper === 'DEGRADED' ? '🟡' : '🔴';

  const entry = `
### ${severityEmoji} [${statusUpper}] Sự Cố: \`${nodeId}\` (${label || nodeId})
- **Thời điểm:** ${timestamp}
- **Độ trễ:** ${latencyMs}ms | **Mã HTTP:** ${statusCode || 'N/A'}
- **Target Endpoint:** \`${targetEndpoint || 'N/A'}\`
- **Mô tả lỗi:** ${message || 'Lỗi không xác định'}

\`\`\`json
${JSON.stringify(details || {}, null, 2)}
\`\`\`

---
`;

  try {
    // Ghi vào file FLOW_INCIDENTS.md ở root workspace
    const rootPath = path.resolve(process.cwd(), '..', 'FLOW_INCIDENTS.md');
    fs.appendFileSync(rootPath, entry, 'utf8');
    res.json({ success: true, message: 'Đã lưu sự cố vào FLOW_INCIDENTS.md' });
  } catch (err: any) {
    // Fallback: ghi vào cwd
    try {
      fs.appendFileSync(path.resolve(process.cwd(), 'FLOW_INCIDENTS.md'), entry, 'utf8');
      res.json({ success: true, message: 'Đã lưu sự cố vào FLOW_INCIDENTS.md cục bộ' });
    } catch {
      res.status(500).json({ success: false, error: err.message });
    }
  }
});

// API Routes
app.use('/api', routes);

// 404 Route Handler
app.use((req: Request, res: Response) => {
  res.status(HTTP_STATUS.NOT_FOUND).json({
    success: false,
    message: `Route ${req.method} ${req.originalUrl} not found`,
  });
});

// Global Error Handler
app.use(errorHandler);

export default app;
