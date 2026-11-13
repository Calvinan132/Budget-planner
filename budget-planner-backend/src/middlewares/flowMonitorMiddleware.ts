import { Request, Response, NextFunction } from 'express';
import { db } from '../config/firebase';
import * as admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';

interface NodeBufferData {
  totalRequests: number;
  errorRequests: number;
  totalLatency: number;
  maxLatency: number;
  lastError: string | null;
  isDirty: boolean;
}

class NodeStatusBuffer {
  private buffer: Map<string, NodeBufferData> = new Map();
  private flushIntervalMs: number;

  constructor(flushIntervalMs: number = 5000) {
    this.flushIntervalMs = flushIntervalMs;
    this.startAutoFlush();
  }

  public record(nodeId: string, latency: number, isError: boolean, errorMsg: string | null = null): void {
    let data = this.buffer.get(nodeId);
    if (!data) {
      data = {
        totalRequests: 0,
        errorRequests: 0,
        totalLatency: 0,
        maxLatency: 0,
        lastError: null,
        isDirty: false
      };
      this.buffer.set(nodeId, data);
    }

    data.totalRequests += 1;
    data.totalLatency += latency;
    data.maxLatency = Math.max(data.maxLatency, latency);
    if (isError) {
      data.errorRequests += 1;
      data.lastError = errorMsg || 'Unknown Error';
    }
    data.isDirty = true;
  }

  private startAutoFlush(): void {
    setInterval(() => {
      this.flush().catch((err) => {
        console.error('[FlowMonitor] Lỗi khi xả bộ đệm status:', err.message);
      });
    }, this.flushIntervalMs);
  }

  public async flush(): Promise<void> {
    for (const [nodeId, data] of this.buffer.entries()) {
      if (!data.isDirty) continue;

      const avgLatency = Math.round(data.totalLatency / Math.max(1, data.totalRequests));
      const errorRate = data.errorRequests / Math.max(1, data.totalRequests);

      let status: 'healthy' | 'degraded' | 'down' = 'healthy';
      if (errorRate > 0.3 || avgLatency > 2000) {
        status = 'down';
      } else if (errorRate > 0.05 || avgLatency > 700) {
        status = 'degraded';
      }

      data.isDirty = false;
      const lastError = data.lastError;
      data.totalRequests = 0;
      data.errorRequests = 0;
      data.totalLatency = 0;
      data.maxLatency = 0;
      data.lastError = null;

      try {
        await db.collection('node_statuses').doc(nodeId).set({
          nodeId,
          status,
          latencyMs: avgLatency,
          lastChecked: admin.firestore.FieldValue.serverTimestamp(),
          lastError,
          source: 'backend'
        }, { merge: true });
      } catch (err: any) {
        // Fallback im lặng nếu firestore chưa setup xong
        // console.warn(`[FlowMonitor] Could not sync ${nodeId} to Firestore:`, err.message);
      }
    }
  }
}

const statusBuffer = new NodeStatusBuffer(5000);

/**
 * Express Middleware gắn vào các Route đại diện cho từng Node nghiệp vụ
 * @param nodeId - ID của Node trên sơ đồ React Flow (vd: 'backend_users', 'backend_plans')
 */
export function flowMonitor(nodeId: string) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const start = process.hrtime();

    res.on('finish', () => {
      const diff = process.hrtime(start);
      const latencyMs = Math.round((diff[0] * 1e9 + diff[1]) / 1e6);
      const statusCode = res.statusCode;
      const isError = statusCode >= 500;
      const errorMsg = isError ? `HTTP ${statusCode} on ${req.method} ${req.originalUrl}` : null;

      statusBuffer.record(nodeId, latencyMs, isError, errorMsg);

      // Ghi log lỗi vào node_logs nếu xảy ra lỗi 5xx
      if (isError) {
        const now = new Date();
        const expireAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

        db.collection('node_logs').add({
          nodeId,
          level: 'ERROR',
          message: errorMsg,
          details: {
            method: req.method,
            url: req.originalUrl,
            statusCode,
            latencyMs
          },
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          expireAt: admin.firestore.Timestamp.fromDate(expireAt)
        }).catch(() => {});

        // Tự động ghi lại sự cố 5xx vào tệp FLOW_INCIDENTS.md để AI có thể đọc và sửa
        try {
          const incidentLog = `
### 🔴 [CRITICAL 5XX] Lỗi Runtime Backend: \`${nodeId}\`
- **Thời điểm:** ${now.toISOString()}
- **Method & URL:** \`${req.method} ${req.originalUrl}\`
- **Mã HTTP:** ${statusCode} | **Độ trễ:** ${latencyMs}ms
- **Thông điệp:** ${errorMsg}

---
`;
          const filePath = path.resolve(process.cwd(), '..', 'FLOW_INCIDENTS.md');
          fs.appendFileSync(filePath, incidentLog, 'utf8');
        } catch {
          // Silent fallback
        }
      }
    });

    next();
  };
}

