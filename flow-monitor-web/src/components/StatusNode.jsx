import React, { memo } from 'react';
import { Handle, Position } from '@xyflow/react';
import { 
  CheckCircle2, 
  AlertTriangle, 
  XCircle, 
  HelpCircle, 
  Play, 
  Smartphone, 
  Server, 
  Cloud, 
  Clock 
} from 'lucide-react';

const categoryBadges = {
  client: { text: 'Flutter Client', color: 'bg-sky-500/10 text-sky-400 border-sky-500/30', icon: Smartphone },
  backend: { text: 'Backend API', color: 'bg-purple-500/10 text-purple-400 border-purple-500/30', icon: Server },
  cloud: { text: 'Firebase Cloud', color: 'bg-amber-500/10 text-amber-400 border-amber-500/30', icon: Cloud },
  cron: { text: 'Background Cron', color: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30', icon: Clock },
};

const statusStyles = {
  healthy: {
    border: 'border-emerald-500/60 hover:border-emerald-400',
    glow: 'shadow-emerald-950/40',
    indicator: 'bg-emerald-400 shadow-emerald-400/50',
    badge: 'text-emerald-300 bg-emerald-950/80 border-emerald-800/60',
    icon: CheckCircle2,
    label: 'HEALTHY'
  },
  degraded: {
    border: 'border-amber-500/60 hover:border-amber-400',
    glow: 'shadow-amber-950/40',
    indicator: 'bg-amber-400 shadow-amber-400/50',
    badge: 'text-amber-300 bg-amber-950/80 border-amber-800/60',
    icon: AlertTriangle,
    label: 'DEGRADED'
  },
  down: {
    border: 'border-rose-500/70 hover:border-rose-400 animate-pulse',
    glow: 'shadow-rose-950/50',
    indicator: 'bg-rose-500 shadow-rose-500/50',
    badge: 'text-rose-300 bg-rose-950/80 border-rose-800/60',
    icon: XCircle,
    label: 'DOWN'
  },
  unknown: {
    border: 'border-slate-700/60 hover:border-slate-600',
    glow: 'shadow-slate-950/20',
    indicator: 'bg-slate-500',
    badge: 'text-slate-400 bg-slate-900 border-slate-700',
    icon: HelpCircle,
    label: 'IDLE'
  }
};

const StatusNode = ({ data, selected }) => {
  const status = data.status || 'unknown';
  const cfg = statusStyles[status] || statusStyles.unknown;
  const StatusIcon = cfg.icon;

  const category = data.category || 'backend';
  const catCfg = categoryBadges[category] || categoryBadges.backend;
  const CategoryIcon = catCfg.icon;

  const handleQuickTest = (e) => {
    e.stopPropagation();
    if (data.onTestNode) {
      data.onTestNode(data.id);
    }
  };

  return (
    <div
      className={`min-w-[220px] max-w-[260px] rounded-2xl border-2 ${cfg.border} bg-slate-900/90 p-3.5 backdrop-blur-xl shadow-xl transition-all duration-300 cursor-pointer ${
        selected ? 'ring-2 ring-cyan-400 ring-offset-2 ring-offset-slate-950 shadow-cyan-950/60 scale-[1.02]' : ''
      }`}
    >
      {/* 4 Handles for flexible connection in any direction */}
      <Handle type="target" position={Position.Top} className="!w-2.5 !h-2.5" />
      <Handle type="target" position={Position.Left} className="!w-2.5 !h-2.5" />

      {/* Header: Category Tag & Status Pill */}
      <div className="flex items-center justify-between gap-1 mb-2">
        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold border ${catCfg.color}`}>
          <CategoryIcon className="w-2.5 h-2.5" />
          {catCfg.text}
        </span>

        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-mono font-bold border ${cfg.badge}`}>
          <span className={`w-1.5 h-1.5 rounded-full ${cfg.indicator} animate-ping`} />
          <StatusIcon className="w-3 h-3" />
          {cfg.label}
        </span>
      </div>

      {/* Main Node Name & Sublabel */}
      <div className="mb-2.5">
        <h3 className="font-bold text-sm text-white truncate tracking-wide">{data.label}</h3>
        {data.sublabel && (
          <p className="text-[11px] font-mono text-cyan-400 truncate opacity-90">{data.sublabel}</p>
        )}
      </div>

      {/* Metrics Row: Latency + Quick Test Trigger */}
      <div className="flex items-center justify-between border-t border-slate-800/80 pt-2 text-[11px] font-mono">
        <div className="text-slate-400">
          Ping: <span className="font-bold text-slate-100">{data.latencyMs != null ? `${data.latencyMs}ms` : '--'}</span>
        </div>

        <button
          onClick={handleQuickTest}
          title="Kiểm tra tính năng này ngay"
          className="flex items-center gap-1 px-2 py-1 rounded-lg bg-cyan-500/10 hover:bg-cyan-500/20 text-cyan-300 border border-cyan-500/30 transition text-[10px] font-bold"
        >
          <Play className="w-2.5 h-2.5 fill-current" />
          Test
        </button>
      </div>

      <Handle type="source" position={Position.Right} className="!w-2.5 !h-2.5" />
      <Handle type="source" position={Position.Bottom} className="!w-2.5 !h-2.5" />
    </div>
  );
};

export default memo(StatusNode);

