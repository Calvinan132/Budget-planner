import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  ReactFlow,
  addEdge,
  applyNodeChanges,
  applyEdgeChanges,
  Background,
  Controls,
  MiniMap
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';

import { 
  db, 
  isFirebaseConfigured, 
  LocalFlowManager 
} from './firebase';
import { 
  doc, 
  getDoc, 
  setDoc, 
  collection, 
  onSnapshot 
} from 'firebase/firestore';

import StatusNode from './components/StatusNode';
import NodeDetailDrawer from './components/NodeDetailDrawer';
import AddNodeModal from './components/AddNodeModal';
import TopNavbar from './components/TopNavbar';
import { defaultFlowNodes, defaultFlowEdges } from './data/defaultFlow';
import { testNodeFeature, verifyDataLinkageChain } from './services/healthCheckService';
import { generateAiFixReport, downloadMarkdownFile } from './utils/aiReportGenerator';

const nodeTypes = {
  statusNode: StatusNode,
};

export default function App() {
  const [nodes, setNodes] = useState([]);
  const [edges, setEdges] = useState([]);
  const [nodeStatuses, setNodeStatuses] = useState({});
  const [selectedNodeId, setSelectedNodeId] = useState(null);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isTestingAll, setIsTestingAll] = useState(false);
  const [isVerifyingLink, setIsVerifyingLink] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  // 1. Tải cấu hình sơ đồ (Firestore -> Local Storage -> defaultFlow)
  useEffect(() => {
    async function loadFlow() {
      if (isFirebaseConfigured && db) {
        try {
          const docRef = doc(db, 'flow_configs', 'main_flow');
          const snap = await getDoc(docRef);
          if (snap.exists()) {
            const data = snap.data();
            setNodes(data.nodes || defaultFlowNodes);
            setEdges(data.edges || defaultFlowEdges);
            return;
          }
        } catch (err) {
          console.warn('[Flow] Could not fetch from Firestore, checking local storage:', err.message);
        }
      }

      // Local storage fallback
      const savedLocal = LocalFlowManager.getFlow();
      if (savedLocal && savedLocal.nodes?.length > 0) {
        setNodes(savedLocal.nodes);
        setEdges(savedLocal.edges || defaultFlowEdges);
      } else {
        setNodes(defaultFlowNodes);
        setEdges(defaultFlowEdges);
      }
    }

    loadFlow();
  }, []);

  // 2. Lắng nghe cập nhật trạng thái thời gian thực
  useEffect(() => {
    // Luôn load trạng thái từ local store trước
    setNodeStatuses(LocalFlowManager.getStatuses());

    let unsubscribeFirestore = null;

    if (isFirebaseConfigured && db) {
      unsubscribeFirestore = onSnapshot(collection(db, 'node_statuses'), (snapshot) => {
        const statuses = {};
        snapshot.forEach((doc) => {
          statuses[doc.id] = doc.data();
        });
        setNodeStatuses(prev => ({ ...prev, ...statuses }));
      }, (err) => {
        console.warn('Firestore onSnapshot error, maintaining local listener:', err.message);
      });
    }

    // Đăng ký local listener để phản hồi tức thì các đợt test
    const unsubscribeLocal = LocalFlowManager.subscribe((statuses) => {
      setNodeStatuses(prev => ({ ...prev, ...statuses }));
    });

    return () => {
      if (unsubscribeFirestore) unsubscribeFirestore();
      unsubscribeLocal();
    };
  }, []);

  // 3. Test 1 Node tính năng cụ thể
  const handleTestSingleNode = useCallback(async (nodeId) => {
    const targetNode = nodes.find(n => n.id === nodeId);
    if (!targetNode) return null;
    return await testNodeFeature(targetNode);
  }, [nodes]);

  // 4. Test toàn bộ các tính năng trong sơ đồ luồng
  const handleRunTestAll = async () => {
    if (isTestingAll) return;
    setIsTestingAll(true);

    try {
      for (const node of nodes) {
        await testNodeFeature(node);
        // Delay nhẹ để tạo hiệu ứng kiểm thử theo từng bước luồng
        await new Promise(r => setTimeout(r, 120));
      }
    } finally {
      setIsTestingAll(false);
    }
  };

  // 4.1. Kiểm tra chuỗi liên kết dữ liệu giữa các dịch vụ
  const handleVerifyLinkage = async () => {
    if (isVerifyingLink) return;
    setIsVerifyingLink(true);
    try {
      const summary = await verifyDataLinkageChain();
      const statusText = summary.isLinked ? 'HOÀN HẢO 🟢' : 'CÓ ĐỨT GÃY 🔴';
      let msg = `Kết Quả Kiểm Tra Chuỗi Liên Kết: ${statusText}\n\n`;
      summary.steps.forEach(s => {
        msg += `[Bước ${s.step}] ${s.target} ➔ ${s.status === 'passed' ? 'PASS' : 'FAIL'} (${s.latency}ms): ${s.note}\n`;
      });
      alert(msg);
    } catch (err) {
      alert(`Lỗi kiểm tra chuỗi: ${err.message}`);
    } finally {
      setIsVerifyingLink(false);
    }
  };

  // 4.2. Xuất báo cáo tổng hợp tất cả sự cố cho AI Agent
  const handleExportAllAiReport = () => {
    const problematicNodes = nodes.filter(n => {
      const s = nodeStatuses[n.id]?.status;
      return s === 'down' || s === 'degraded';
    });

    if (problematicNodes.length === 0) {
      alert('Tất cả các tính năng hiện tại đều hoạt động tốt (HEALTHY) hoặc chưa kiểm tra!');
      return;
    }

    let fullReport = `# 🤖 Báo Cáo Tổng Hợp Sự Cố Hệ Thống Cho AI (System Incidents Report)\n\n`;
    fullReport += `> **Thời gian tạo:** ${new Date().toISOString()}\n`;
    fullReport += `> **Số node gặp sự cố:** ${problematicNodes.length}\n\n---\n\n`;

    problematicNodes.forEach((node) => {
      const statusData = nodeStatuses[node.id] || {};
      fullReport += generateAiFixReport({
        nodeId: node.id,
        label: node.data?.label,
        status: statusData.status || 'down',
        latencyMs: statusData.latencyMs || 0,
        statusCode: statusData.statusCode || 500,
        message: statusData.lastError || 'Tính năng không phản hồi',
        targetEndpoint: node.data?.targetEndpoint
      });
      fullReport += `\n\n---\n\n`;
    });

    downloadMarkdownFile(`AI_ALL_INCIDENTS_${Date.now()}.md`, fullReport);
  };

  // 5. Thêm node tính năng mới
  const handleAddNode = (newNode) => {
    setNodes(nds => [...nds, newNode]);
    LocalFlowManager.updateStatus(newNode.id, {
      label: newNode.data.label,
      status: 'unknown',
      latencyMs: null
    });
  };

  // 6. Reset về flow mặc định của Budget Planner
  const handleResetDefaultFlow = () => {
    if (window.confirm('Bạn có chắc muốn khôi phục sơ đồ luồng về thiết kế mẫu ban đầu?')) {
      setNodes(defaultFlowNodes);
      setEdges(defaultFlowEdges);
      LocalFlowManager.saveFlow({ nodes: defaultFlowNodes, edges: defaultFlowEdges });
    }
  };

  // 7. Lưu sơ đồ vào Firestore & Local Storage
  const handleSaveFlow = async () => {
    setIsSaving(true);
    const flowPayload = {
      nodes: nodes.map(n => ({
        id: n.id,
        type: n.type,
        position: n.position,
        data: n.data
      })),
      edges,
      updatedAt: new Date().toISOString()
    };

    // Save local
    LocalFlowManager.saveFlow(flowPayload);

    // Save Firestore if configured
    if (isFirebaseConfigured && db) {
      try {
        await setDoc(doc(db, 'flow_configs', 'main_flow'), flowPayload);
        alert('Đã lưu cấu hình sơ đồ lên Cloud Firestore thành công!');
      } catch (err) {
        alert(`Lưu cục bộ thành công! (Lỗi Firestore: ${err.message})`);
      }
    } else {
      alert('Đã lưu cấu hình sơ đồ cục bộ thành công!');
    }
    setIsSaving(false);
  };

  // 8. Đồng bộ real-time status vào từng Node hiển thị
  const computedNodes = useMemo(() => {
    return nodes.map((node) => {
      const statusData = nodeStatuses[node.id] || {};
      return {
        ...node,
        data: {
          ...node.data,
          id: node.id,
          status: statusData.status || 'unknown',
          latencyMs: statusData.latencyMs,
          lastError: statusData.lastError,
          onTestNode: handleTestSingleNode
        }
      };
    });
  }, [nodes, nodeStatuses, handleTestSingleNode]);

  // 9. Đồng bộ style cho Edges (Dây nối phát sáng/chạy khi Healthy, đỏ khi Down)
  const computedEdges = useMemo(() => {
    return edges.map((edge) => {
      const sourceStatus = nodeStatuses[edge.source]?.status;
      const targetStatus = nodeStatuses[edge.target]?.status;
      const isDown = sourceStatus === 'down' || targetStatus === 'down';
      const isDegraded = sourceStatus === 'degraded' || targetStatus === 'degraded';

      let stroke = '#10b981'; // emerald
      if (isDown) stroke = '#f43f5e'; // rose
      else if (isDegraded) stroke = '#f59e0b'; // amber
      else if (sourceStatus === 'unknown') stroke = '#475569'; // slate

      return {
        ...edge,
        animated: !isDown && sourceStatus !== 'unknown',
        style: {
          stroke,
          strokeWidth: isDown ? 2.5 : 2,
          strokeDasharray: isDown ? '6,6' : undefined,
          transition: 'stroke 0.3s ease'
        }
      };
    });
  }, [edges, nodeStatuses]);

  const onNodesChange = useCallback((changes) => setNodes((nds) => applyNodeChanges(changes, nds)), []);
  const onEdgesChange = useCallback((changes) => setEdges((eds) => applyEdgeChanges(changes, eds)), []);
  const onConnect = useCallback((connection) => setEdges((eds) => addEdge({ ...connection, animated: true }, eds)), []);

  const activeSelectedNode = useMemo(() => {
    return nodes.find(n => n.id === selectedNodeId) || null;
  }, [nodes, selectedNodeId]);

  return (
    <div className="w-screen h-screen bg-slate-950 text-slate-100 flex flex-col font-sans select-none overflow-hidden">
      {/* Top Navbar */}
      <TopNavbar
        nodes={nodes}
        nodeStatuses={nodeStatuses}
        isTestingAll={isTestingAll}
        isVerifyingLink={isVerifyingLink}
        isSaving={isSaving}
        onRunTestAll={handleRunTestAll}
        onVerifyLinkage={handleVerifyLinkage}
        onOpenAddModal={() => setIsAddModalOpen(true)}
        onResetDefaultFlow={handleResetDefaultFlow}
        onSaveFlow={handleSaveFlow}
        onExportAllAiReport={handleExportAllAiReport}
      />

      {/* Main React Flow Canvas */}
      <div className="flex-1 relative">
        <ReactFlow
          nodes={computedNodes}
          edges={computedEdges}
          onNodesChange={onNodesChange}
          onEdgesChange={onEdgesChange}
          onConnect={onConnect}
          nodeTypes={nodeTypes}
          onNodeClick={(_, node) => setSelectedNodeId(node.id)}
          fitView
          minZoom={0.2}
          maxZoom={1.8}
        >
          <Background color="#1e293b" gap={24} size={1.2} />
          <Controls className="!bg-slate-900/90 !border-slate-800 !fill-slate-300 !rounded-xl !shadow-2xl" />
          <MiniMap
            nodeStrokeColor="#0f172a"
            nodeColor={(n) => {
              const status = nodeStatuses[n.id]?.status;
              if (status === 'healthy') return '#10b981';
              if (status === 'degraded') return '#f59e0b';
              if (status === 'down') return '#f43f5e';
              return '#475569';
            }}
            className="!bg-slate-900/90 !border-slate-800 !rounded-2xl !overflow-hidden shadow-2xl"
          />
        </ReactFlow>

        {/* Side Inspector Drawer */}
        {activeSelectedNode && (
          <NodeDetailDrawer
            node={activeSelectedNode}
            nodeStatus={nodeStatuses[activeSelectedNode.id]}
            onTestNode={handleTestSingleNode}
            onClose={() => setSelectedNodeId(null)}
          />
        )}
      </div>

      {/* Add Custom Feature Node Modal */}
      <AddNodeModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        onAddNode={handleAddNode}
      />
    </div>
  );
}

