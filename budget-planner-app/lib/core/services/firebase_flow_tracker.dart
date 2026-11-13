import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Class hỗ trợ giám sát luồng hoạt động phía Mobile Client (Flutter)
/// Tự động đo thời gian thực thi, bắt lỗi và đồng bộ trạng thái lên Firestore
class FirebaseFlowTracker {
  static final FirebaseFlowTracker _instance = FirebaseFlowTracker._internal();
  factory FirebaseFlowTracker() => _instance;
  FirebaseFlowTracker._internal();

  FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore => _firestoreInstance ??= FirebaseFirestore.instance;

  // Bộ nhớ đệm lưu thời điểm gửi status gần nhất cho từng Node (Rate Limit: 15s)
  final Map<String, DateTime> _lastReportedTime = {};
  static const Duration _throttleDuration = Duration(seconds: 15);

  // Buffer lưu logs lỗi trước khi xả theo Batch
  final List<Map<String, dynamic>> _logBuffer = [];
  Timer? _batchTimer;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _batchTimer = Timer.periodic(const Duration(seconds: 10), (_) => _flushLogs());
    developer.log('FirebaseFlowTracker đã sẵn sàng.', name: 'FlowTracker');
  }

  void dispose() {
    _batchTimer?.cancel();
    _flushLogs();
  }

  /// Wrapper bọc một tác vụ nghiệp vụ bất đồng bộ (ví dụ: login, fetch budget, add expense)
  Future<T> trackOperation<T>({
    required String nodeId,
    required String label,
    required Future<T> Function() action,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();

      final latencyMs = stopwatch.elapsedMilliseconds;
      _reportStatusThrottled(
        nodeId: nodeId,
        label: label,
        status: latencyMs > 1500 ? 'degraded' : 'healthy',
        latencyMs: latencyMs,
      );

      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      final latencyMs = stopwatch.elapsedMilliseconds;

      // Khi xảy ra lỗi: Báo trạng thái DOWN ngay lập tức và ghi log lỗi
      _updateNodeStatus(
        nodeId: nodeId,
        label: label,
        status: 'down',
        latencyMs: latencyMs,
        lastError: error.toString(),
      );

      _enqueueLog(
        nodeId: nodeId,
        level: 'ERROR',
        message: error.toString(),
        details: {
          'latencyMs': latencyMs,
          'stack': stackTrace.toString().split('\n').take(4).toList(),
        },
      );

      rethrow;
    }
  }

  void _reportStatusThrottled({
    required String nodeId,
    required String label,
    required String status,
    required int latencyMs,
  }) {
    final now = DateTime.now();
    final lastTime = _lastReportedTime[nodeId];

    if (lastTime == null || now.difference(lastTime) > _throttleDuration) {
      _lastReportedTime[nodeId] = now;
      _updateNodeStatus(
        nodeId: nodeId,
        label: label,
        status: status,
        latencyMs: latencyMs,
      );
    }
  }

  Future<void> _updateNodeStatus({
    required String nodeId,
    required String label,
    required String status,
    required int latencyMs,
    String? lastError,
  }) async {
    try {
      await _firestore.collection('node_statuses').doc(nodeId).set({
        'nodeId': nodeId,
        'label': label,
        'status': status,
        'latencyMs': latencyMs,
        'lastChecked': FieldValue.serverTimestamp(),
        'lastError': lastError,
        'source': 'client',
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log('Không thể gửi node_status: $e', name: 'FlowTracker');
    }
  }

  void _enqueueLog({
    required String nodeId,
    required String level,
    required String message,
    Map<String, dynamic>? details,
  }) {
    final now = DateTime.now();
    final expireAt = now.add(const Duration(days: 7)); // 7-day TTL

    _logBuffer.add({
      'nodeId': nodeId,
      'level': level,
      'message': message,
      'details': details ?? {},
      'timestamp': FieldValue.serverTimestamp(),
      'expireAt': Timestamp.fromDate(expireAt),
    });

    if (_logBuffer.length >= 8) {
      _flushLogs();
    }
  }

  Future<void> _flushLogs() async {
    if (_logBuffer.isEmpty) return;

    final List<Map<String, dynamic>> itemsToWrite = List.from(_logBuffer);
    _logBuffer.clear();

    try {
      final batch = _firestore.batch();
      for (final item in itemsToWrite) {
        final docRef = _firestore.collection('node_logs').doc();
        batch.set(docRef, item);
      }
      await batch.commit();
    } catch (e) {
      developer.log('Không thể flush log batch: $e', name: 'FlowTracker');
    }
  }
}

