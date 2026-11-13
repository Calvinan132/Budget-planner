import { initializeApp, getApps, getApp } from 'firebase/app';
import { 
  getFirestore, 
  collection, 
  doc, 
  getDoc, 
  setDoc, 
  onSnapshot, 
  query, 
  where, 
  orderBy, 
  limit, 
  serverTimestamp,
  addDoc
} from 'firebase/firestore';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || "",
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || "budget-planner-dev.firebaseapp.com",
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || "budget-planner-dev",
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || "budget-planner-dev.appspot.com",
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "",
  appId: import.meta.env.VITE_FIREBASE_APP_ID || ""
};

export const isFirebaseConfigured = Boolean(
  firebaseConfig.apiKey && 
  firebaseConfig.projectId && 
  firebaseConfig.apiKey.length > 5
);

let db = null;
let app = null;

if (isFirebaseConfigured) {
  try {
    app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
    db = getFirestore(app);
    console.log('[Firebase] Cloud Firestore initialized successfully.');
  } catch (err) {
    console.warn('[Firebase] Initialization error, falling back to local mode:', err);
  }
} else {
  console.info('[Firebase] Config API key not set in .env. Running in Interactive Local & Live Backend mode.');
}

export { db };

// Local Storage Fallback & State Dispatcher for offline / non-Firebase dev
class LocalFlowManager {
  static FLOW_KEY = 'budget_planner_flow_config';
  static STATUS_KEY = 'budget_planner_node_statuses';
  static LOGS_KEY = 'budget_planner_node_logs';
  static listeners = new Set();

  static subscribe(callback) {
    this.listeners.add(callback);
    return () => this.listeners.delete(callback);
  }

  static notify() {
    const statuses = this.getStatuses();
    this.listeners.forEach(cb => cb(statuses));
  }

  static getFlow() {
    try {
      const data = localStorage.getItem(this.FLOW_KEY);
      return data ? JSON.parse(data) : null;
    } catch {
      return null;
    }
  }

  static saveFlow(flow) {
    localStorage.setItem(this.FLOW_KEY, JSON.stringify(flow));
  }

  static getStatuses() {
    try {
      const data = localStorage.getItem(this.STATUS_KEY);
      return data ? JSON.parse(data) : {};
    } catch {
      return {};
    }
  }

  static updateStatus(nodeId, statusData) {
    const statuses = this.getStatuses();
    statuses[nodeId] = {
      nodeId,
      ...statusData,
      lastChecked: new Date().toISOString()
    };
    localStorage.setItem(this.STATUS_KEY, JSON.stringify(statuses));
    this.notify();
  }

  static addLog(logEntry) {
    try {
      const logs = JSON.parse(localStorage.getItem(this.LOGS_KEY) || '[]');
      const newLog = {
        id: `local_log_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        ...logEntry,
        timestamp: new Date().toISOString()
      };
      logs.unshift(newLog);
      // Keep up to 100 logs
      if (logs.length > 100) logs.pop();
      localStorage.setItem(this.LOGS_KEY, JSON.stringify(logs));
      return newLog;
    } catch {
      return null;
    }
  }

  static getLogs(nodeId) {
    try {
      const logs = JSON.parse(localStorage.getItem(this.LOGS_KEY) || '[]');
      if (!nodeId) return logs;
      return logs.filter(l => l.nodeId === nodeId);
    } catch {
      return [];
    }
  }
}

export { LocalFlowManager };

