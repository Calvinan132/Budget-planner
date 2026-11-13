import React, { useState } from 'react';
import { X, PlusCircle } from 'lucide-react';

export default function AddNodeModal({ isOpen, onClose, onAddNode }) {
  const [formData, setFormData] = useState({
    id: '',
    label: '',
    sublabel: '',
    category: 'backend',
    testType: 'http_get',
    targetEndpoint: '',
    description: ''
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.id.trim() || !formData.label.trim()) {
      alert('Vui lòng nhập Node ID và Tên hiển thị!');
      return;
    }

    onAddNode({
      id: formData.id.trim().toLowerCase().replace(/\s+/g, '_'),
      type: 'statusNode',
      position: { x: 300 + Math.random() * 120, y: 200 + Math.random() * 120 },
      data: {
        label: formData.label.trim(),
        sublabel: formData.sublabel.trim(),
        category: formData.category,
        testType: formData.testType,
        targetEndpoint: formData.targetEndpoint.trim(),
        description: formData.description.trim()
      }
    });

    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-lg shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="p-4 border-b border-slate-800 flex items-center justify-between bg-slate-950/60">
          <div className="flex items-center gap-2">
            <PlusCircle className="w-5 h-5 text-cyan-400" />
            <h3 className="text-sm font-bold text-white">Thêm Tính Năng Mới Vào Flow</h3>
          </div>
          <button onClick={onClose} className="p-1 rounded text-slate-400 hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-5 space-y-3.5 text-xs">
          <div>
            <label className="block text-slate-300 font-semibold mb-1">Mã Node (ID duy nhất): *</label>
            <input
              type="text"
              required
              placeholder="ví dụ: backend_export_pdf, client_checkout"
              value={formData.id}
              onChange={(e) => setFormData({ ...formData, id: e.target.value })}
              className="w-full bg-slate-950 border border-slate-800 rounded-lg p-2.5 text-slate-100 font-mono focus:border-cyan-500 focus:outline-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-slate-300 font-semibold mb-1">Tên Tính Năng (Label): *</label>
              <input
                type="text"
                required
                placeholder="ví dụ: Xuất Báo Cáo PDF"
                value={formData.label}
                onChange={(e) => setFormData({ ...formData, label: e.target.value })}
                className="w-full bg-slate-950 border border-slate-800 rounded-lg p-2.5 text-slate-100 focus:border-cyan-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="block text-slate-300 font-semibold mb-1">Phụ đề (Sublabel):</label>
              <input
                type="text"
                placeholder="ví dụ: POST /api/reports/pdf"
                value={formData.sublabel}
                onChange={(e) => setFormData({ ...formData, sublabel: e.target.value })}
                className="w-full bg-slate-950 border border-slate-800 rounded-lg p-2.5 text-slate-100 font-mono focus:border-cyan-500 focus:outline-none"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-slate-300 font-semibold mb-1">Phân loại (Category):</label>
              <select
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                className="w-full bg-slate-950 border border-slate-800 rounded-lg p-2.5 text-slate-100 focus:border-cyan-500 focus:outline-none"
              >
                <option value="backend">Backend API</option>
                <option value="client">Flutter Client</option>
                <option value="cloud">Firebase Cloud</option>
                <option value="cron">Cron Job</option>
              </select>
            </div>
            <div>
              <label className="block text-slate-300 font-semibold mb-1">Cơ chế kiểm tra (Test Type):</label>
              <select
                value={formData.testType}
                onChange={(e) => setFormData({ ...formData, testType: e.target.value })}
                className="w-full bg-slate-950 border border-slate-800 rounded-lg p-2.5 text-slate-100 focus:border-cyan-500 focus:outline-none"
              >
                <option value="http_get">HTTP GET Endpoint</option>
                <option value="client_sim">Flutter Client Simulation</option>
                <option value="firebase_auth">Firebase Auth Ping</option>
                <option value="firestore_ping">Firestore DB Ping</option>
                <option value="cron_status">Cron Task Check</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-slate-300 font-semibold mb-1">Endpoint / Hành động cần kiểm tra:</label>
            <input
              type="text"
              placeholder="ví dụ: /api/daily hoặc client:sync_data"
              value={formData.targetEndpoint}
              onChange={(e) => setFormData({ ...formData, targetEndpoint: e.target.value })}
              className="w-full bg-slate-950 border border-slate-800 rounded-lg p-2.5 text-slate-100 font-mono focus:border-cyan-500 focus:outline-none"
            />
          </div>

          <div>
            <label className="block text-slate-300 font-semibold mb-1">Mô tả luồng hoạt động:</label>
            <textarea
              rows={2}
              placeholder="Mô tả tóm tắt tính năng này xử lý nghiệp vụ gì trong flow..."
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full bg-slate-950 border border-slate-800 rounded-lg p-2.5 text-slate-100 focus:border-cyan-500 focus:outline-none resize-none"
            />
          </div>

          <div className="pt-2 flex justify-end gap-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 font-medium"
            >
              Hủy Bỏ
            </button>
            <button
              type="submit"
              className="px-5 py-2 rounded-lg bg-cyan-600 hover:bg-cyan-500 text-white font-bold shadow-lg shadow-cyan-900/50"
            >
              Thêm Vào Sơ Đồ
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

