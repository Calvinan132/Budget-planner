import React from 'react';
import { 
  Activity, 
  Play, 
  Plus, 
  Save, 
  RotateCcw, 
  RefreshCw, 
  CheckCircle2,
  AlertTriangle,
  XCircle,
  Link2,
  Bot
} from 'lucide-react';
import { isFirebaseConfigured } from '../firebase';

export default function TopNavbar({
  nodes,
  nodeStatuses,
  isTestingAll,
  isVerifyingLink,
  isSaving,
  onRunTestAll,
  onVerifyLinkage,
  onOpenAddModal,
  onResetDefaultFlow,
  onSaveFlow,
  onExportAllAiReport
}) {
  // Compute health stats
  let healthy = 0;
  let degraded = 0;
  let down = 0;

  nodes.forEach(n => {
    const s = nodeStatuses[n.id]?.status;
    if (s === 'healthy') healthy++;
    else if (s === 'degraded') degraded++;
    else if (s === 'down') down++;
  });

  return (
    <header className="h-16 border-b border-slate-800 bg-slate-900/90 backdrop-blur-xl px-5 flex items-center justify-between z-20 shrink-0">
      {/* Brand & Connection State */}
      <div className="flex items-center gap-3">
        <div className="relative flex items-center justify-center w-9 h-9 rounded-xl bg-cyan-500/10 border border-cyan-500/30">
          <Activity className="w-5 h-5 text-cyan-400" />
        </div>

        <div>
          <div className="flex items-center gap-2">
            <h1 className="font-extrabold text-sm tracking-wide text-white">
              Budget Planner <span className="bg-gradient-to-r from-cyan-400 to-emerald-400 bg-clip-text text-transparent">Flow & Health Monitor</span>
            </h1>
            <span className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-semibold border ${
              isFirebaseConfigured
                ? 'bg-emerald-950/60 text-emerald-400 border-emerald-800/80'
                : 'bg-amber-950/60 text-amber-400 border-amber-800/80'
            }`}>
              {isFirebaseConfigured ? '● Firestore Live Sync' : '○ Local/Direct API Mode'}
            </span>
          </div>
          <p className="text-[11px] text-slate-400">Kiểm thử tính năng & giám sát luồng hoạt động ứng dụng</p>
        </div>
      </div>

      {/* Live Health Summary Badges */}
      <div className="hidden lg:flex items-center gap-2 bg-slate-950/60 border border-slate-800/80 rounded-xl px-3 py-1.5 text-xs font-mono">
        <span className="text-slate-400">Hệ thống ({nodes.length} nodes):</span>
        <span className="flex items-center gap-1 text-emerald-400 font-bold">
          <CheckCircle2 className="w-3.5 h-3.5" /> {healthy}
        </span>
        <span className="text-slate-600">|</span>
        <span className="flex items-center gap-1 text-amber-400 font-bold">
          <AlertTriangle className="w-3.5 h-3.5" /> {degraded}
        </span>
        <span className="text-slate-600">|</span>
        <span className="flex items-center gap-1 text-rose-400 font-bold">
          <XCircle className="w-3.5 h-3.5" /> {down}
        </span>
      </div>

      {/* Action Buttons Toolbar */}
      <div className="flex items-center gap-2">
        {/* Run Full Flow Health Check */}
        <button
          onClick={onRunTestAll}
          disabled={isTestingAll || isVerifyingLink}
          className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white font-bold text-xs shadow-lg shadow-emerald-950/40 transition disabled:opacity-50"
        >
          {isTestingAll ? <RefreshCw className="w-3.5 h-3.5 animate-spin" /> : <Play className="w-3.5 h-3.5 fill-current" />}
          {isTestingAll ? 'Đang Kiểm Tra...' : 'Kiểm Tra Toàn Bộ Flow'}
        </button>

        {/* Verify Data Linkage Chain */}
        <button
          onClick={onVerifyLinkage}
          disabled={isTestingAll || isVerifyingLink}
          title="Kiểm tra xem dữ liệu có truyền liên kết thông suốt giữa các tầng không"
          className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-gradient-to-r from-cyan-600 to-indigo-600 hover:from-cyan-500 hover:to-indigo-500 text-white font-bold text-xs shadow-lg shadow-cyan-950/40 transition disabled:opacity-50"
        >
          {isVerifyingLink ? <RefreshCw className="w-3.5 h-3.5 animate-spin" /> : <Link2 className="w-3.5 h-3.5" />}
          {isVerifyingLink ? 'Đang Kiểm Tra Chuỗi...' : 'Kiểm Tra Chuỗi Liên Kết'}
        </button>

        {/* Add Node */}
        <button
          onClick={onOpenAddModal}
          className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 font-semibold text-xs transition"
        >
          <Plus className="w-3.5 h-3.5 text-cyan-400" />
          Thêm Tính Năng
        </button>

        {/* Export AI Incident Report */}
        {(down > 0 || degraded > 0) && (
          <button
            onClick={onExportAllAiReport}
            title="Xuất báo cáo Markdown tổng hợp sự cố để gửi cho AI sửa code"
            className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-rose-600/90 hover:bg-rose-500 text-white font-bold text-xs shadow-lg shadow-rose-950/50 animate-pulse transition"
          >
            <Bot className="w-3.5 h-3.5" />
            Báo Cáo AI ({down + degraded})
          </button>
        )}

        {/* Reset Default Flow */}
        <button
          onClick={onResetDefaultFlow}
          title="Khôi phục sơ đồ mẫu ban đầu của Budget Planner"
          className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white border border-slate-700 transition"
        >
          <RotateCcw className="w-4 h-4" />
        </button>

        {/* Save Flow */}
        <button
          onClick={onSaveFlow}
          disabled={isSaving}
          className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-cyan-600 hover:bg-cyan-500 text-white font-bold text-xs shadow-lg shadow-cyan-950/40 transition disabled:opacity-50"
        >
          {isSaving ? <RefreshCw className="w-3.5 h-3.5 animate-spin" /> : <Save className="w-3.5 h-3.5" />}
          Lưu Sơ Đồ
        </button>
      </div>
    </header>
  );
}

