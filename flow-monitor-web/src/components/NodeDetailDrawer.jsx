import React, { useState, useEffect } from 'react';
import {
  X,
  Play,
  Clock,
  Terminal,
  Layers,
  AlertCircle,
  CheckCircle,
  AlertTriangle,
  RefreshCw,
  ExternalLink,
  Bot,
  Copy,
  Download,
  Check
} from 'lucide-react';
import { db, isFirebaseConfigured, LocalFlowManager } from '../firebase';
import { collection, query, where, orderBy, limit, onSnapshot } from 'firebase/firestore';
import {
  generateAiFixReport,
  downloadMarkdownFile,
  copyToClipboard,
  nodeSourceFileMap
} from '../utils/aiReportGenerator';

export default function NodeDetailDrawer({ node, nodeStatus, onTestNode, onClose }) {
  const [logs, setLogs] = useState([]);
  const [isTesting, setIsTesting] = useState(false);
  const [testResult, setTestResult] = useState(null);
  const [hasCopied, setHasCopied] = useState(false);

  const nodeId = node?.id;
  const data = node?.data || {};
  const status = nodeStatus?.status || 'unknown';
  const isProblematic = status === 'down' || status === 'degraded';
  const fileHints = nodeSourceFileMap[nodeId] || null;

  const handleCopyAiPrompt = async () => {
    const report = generateAiFixReport({
      nodeId,
      label: data.label,
      status,
      latencyMs: nodeStatus?.latencyMs || testResult?.latencyMs || 0,
      statusCode: testResult?.statusCode || 500,
      message: testResult?.message || nodeStatus?.lastError || 'Tính năng không phản hồi',
      details: testResult?.details || null,
      targetEndpoint: data.targetEndpoint
    });
    await copyToClipboard(report);
    setHasCopied(true);
    setTimeout(() => setHasCopied(false), 2500);
  };

  const handleDownloadAiReport = () => {
    const report = generateAiFixReport({
      nodeId,
      label: data.label,
      status,
      latencyMs: nodeStatus?.latencyMs || testResult?.latencyMs || 0,
      statusCode: testResult?.statusCode || 500,
      message: testResult?.message || nodeStatus?.lastError || 'Tính năng không phản hồi',
      details: testResult?.details || null,
      targetEndpoint: data.targetEndpoint
    });
    downloadMarkdownFile(`AI_FIX_${nodeId}_${Date.now()}.md`, report);
  };

  // Load logs: from Firestore if configured, else from LocalFlowManager
  useEffect(() => {
    if (!nodeId) return;

    if (isFirebaseConfigured && db) {
      const q = query(
        collection(db, 'node_logs'),
        where('nodeId', '==', nodeId),
        orderBy('timestamp', 'desc'),
        limit(25)
      );

      const unsubscribe = onSnapshot(q, (snapshot) => {
        const list = snapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data(),
          timestamp: doc.data().timestamp?.toDate ? doc.data().timestamp.toDate().toLocaleTimeString() : new Date().toLocaleTimeString()
        }));
        setLogs(list);
      }, (err) => {
        console.warn('Firestore logs fallback to local:', err.message);
        setLogs(LocalFlowManager.getLogs(nodeId));
      });

      return () => unsubscribe();
    } else {
      // Local fallback
      setLogs(LocalFlowManager.getLogs(nodeId));
      const interval = setInterval(() => {
        setLogs(LocalFlowManager.getLogs(nodeId));
      }, 1000);
      return () => clearInterval(interval);
    }
  }, [nodeId]);

  const handleRunTest = async () => {
    setIsTesting(true);
    setTestResult(null);
    try {
      const res = await onTestNode(nodeId);
      setTestResult(res);
      setLogs(LocalFlowManager.getLogs(nodeId));
    } catch (err) {
      setTestResult({ status: 'down', message: err.message });
    } finally {
      setIsTesting(false);
    }
  };

  return (
    <div className="fixed top-0 right-0 h-full w-[460px] bg-slate-900/98 border-l border-slate-800 backdrop-blur-2xl shadow-2xl z-50 flex flex-col transition-all duration-300">
      {/* Header */}
      <div className="p-4 border-b border-slate-800 flex items-center justify-between bg-slate-950/60">
        <div className="flex items-center gap-2.5">
          <Layers className="w-5 h-5 text-cyan-400" />
          <div>
            <h2 className="text-sm font-bold text-white tracking-wide truncate max-w-[320px]">
              {data.label || nodeId}
            </h2>
            <p className="text-[11px] font-mono text-cyan-400">{nodeId}</p>
          </div>
        </div>

        <button
          onClick={onClose}
          className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
        >
          <X className="w-5 h-5" />
        </button>
      </div>

      {/* Action / Trigger Banner */}
      <div className="p-4 border-b border-slate-800 bg-slate-900/60 flex items-center justify-between">
        <div>
          <span className="text-[10px] uppercase font-bold text-slate-400 block mb-0.5">Trạng thái tính năng</span>
          <div className="flex items-center gap-2">
            <span className={`inline-block w-2.5 h-2.5 rounded-full ${status === 'healthy' ? 'bg-emerald-400' : status === 'degraded' ? 'bg-amber-400' : status === 'down' ? 'bg-rose-500' : 'bg-slate-500'
              }`} />
            <span className="font-mono text-xs font-bold uppercase text-white">
              {status}
            </span>
            {nodeStatus?.latencyMs != null && (
              <span className="text-xs font-mono text-slate-400">({nodeStatus.latencyMs}ms)</span>
            )}
          </div>
        </div>

        <button
          onClick={handleRunTest}
          disabled={isTesting}
          className="flex items-center gap-2 px-4 py-2 rounded-xl bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-500 hover:to-blue-500 text-white font-bold text-xs shadow-lg shadow-cyan-900/40 transition disabled:opacity-50"
        >
          {isTesting ? <RefreshCw className="w-3.5 h-3.5 animate-spin" /> : <Play className="w-3.5 h-3.5 fill-current" />}
          Kiểm Tra Ngay
        </button>
      </div>

      {/* Node Spec & Config */}
      <div className="p-4 border-b border-slate-800 space-y-2 text-xs">
        <div className="flex justify-between py-1 border-b border-slate-800/60">
          <span className="text-slate-400">Phân loại:</span>
          <span className="font-mono font-semibold text-cyan-300 uppercase">{data.category || 'Backend'}</span>
        </div>
        <div className="flex justify-between py-1 border-b border-slate-800/60">
          <span className="text-slate-400">Mục tiêu kiểm thử:</span>
          <span className="font-mono text-slate-200">{data.targetEndpoint || 'N/A'}</span>
        </div>
        {data.description && (
          <div className="py-1">
            <span className="text-slate-400 block mb-1">Mô tả luồng:</span>
            <p className="text-slate-300 text-[11px] leading-relaxed bg-slate-950/60 p-2.5 rounded-lg border border-slate-800/80">
              {data.description}
            </p>
          </div>
        )}
      </div>

      {/* Latest Live Test Result (if any) */}
      {testResult && (
        <div className="p-4 border-b border-slate-800 bg-slate-950/80">
          <div className="flex items-center gap-2 mb-2 text-xs font-bold text-slate-200">
            <Terminal className="w-4 h-4 text-cyan-400" />
            Kết Quả Kiểm Tra Gần Nhất
          </div>
          <div className={`p-2.5 rounded-lg text-xs font-mono border ${testResult.status === 'healthy'
            ? 'bg-emerald-950/50 border-emerald-800 text-emerald-200'
            : testResult.status === 'degraded'
              ? 'bg-amber-950/50 border-amber-800 text-amber-200'
              : 'bg-rose-950/50 border-rose-800 text-rose-200'
            }`}>
            <p className="font-semibold">{testResult.message}</p>
            <p className="text-[10px] opacity-75 mt-0.5">Latency: {testResult.latencyMs}ms | Code: {testResult.statusCode || '--'}</p>
          </div>
        </div>
      )}

      {/* Latency Mini Visualizer */}
      <div className="p-4 border-b border-slate-800 bg-slate-950/40">
        <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
          <span>Lịch sử độ trễ gần đây</span>
          <span className="font-mono text-[10px]">Đơn vị: ms</span>
        </div>
        <div className="h-14 flex items-end gap-1.5 pt-1">
          {logs.slice(0, 16).reverse().map((l, idx) => {
            const lat = l.details?.latencyMs || 40;
            const height = Math.min(100, Math.max(16, (lat / 1200) * 100));
            const isErr = l.level === 'ERROR';
            return (
              <div key={idx} className="flex-1 flex flex-col items-center group relative">
                <div
                  style={{ height: `${height}%` }}
                  className={`w-full rounded-t transition-all ${isErr ? 'bg-rose-500' : lat > 600 ? 'bg-amber-400' : 'bg-emerald-400'
                    }`}
                />
                <span className="absolute -top-7 hidden group-hover:block bg-slate-800 text-white text-[10px] px-1.5 py-0.5 rounded shadow z-20 whitespace-nowrap">
                  {lat}ms
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Activity / Error Logs */}
      <div className="flex-1 overflow-y-auto p-4 space-y-2.5">
        <div className="flex items-center justify-between text-xs font-semibold text-slate-400 mb-1">
          <span className="flex items-center gap-1.5">
            <Clock className="w-3.5 h-3.5" />
            Nhật Ký Hoạt Động (Logs)
          </span>
          <span className="text-[10px] text-slate-500">{logs.length} sự kiện</span>
        </div>

        {logs.length === 0 ? (
          <div className="text-center py-10 text-xs text-slate-500">
            Chưa có log cho node này. Bấm "Kiểm Tra Ngay" để chạy thử.
          </div>
        ) : (
          logs.map((log) => (
            <div
              key={log.id}
              className="p-3 bg-slate-950/70 border border-slate-800/80 rounded-xl text-xs font-mono space-y-1.5 hover:border-slate-700 transition"
            >
              <div className="flex items-center justify-between">
                <span className={`px-2 py-0.5 rounded text-[10px] font-bold border ${log.level === 'ERROR'
                  ? 'bg-rose-950 text-rose-300 border-rose-800'
                  : log.level === 'WARN'
                    ? 'bg-amber-950 text-amber-300 border-amber-800'
                    : 'bg-slate-800 text-slate-300 border-slate-700'
                  }`}>
                  {log.level}
                </span>
                <span className="text-[10px] text-slate-500">{log.timestamp}</span>
              </div>
              <p className="text-slate-200 text-[11px] leading-relaxed break-words">{log.message}</p>
              {log.details && Object.keys(log.details).length > 0 && (
                <pre className="p-2 bg-slate-900/90 rounded text-[10px] text-slate-400 overflow-x-auto max-h-28 border border-slate-800/60">
                  {JSON.stringify(log.details, null, 2)}
                </pre>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
}

