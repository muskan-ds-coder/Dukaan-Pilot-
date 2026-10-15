import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../local/database_helper.dart';

class SyncStatusState {
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final bool isOnline;
  final String? lastError;

  const SyncStatusState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.isOnline = true,
    this.lastError,
  });

  SyncStatusState copyWith({
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncedAt,
    bool? isOnline,
    String? lastError,
  }) {
    return SyncStatusState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isOnline: isOnline ?? this.isOnline,
      lastError: lastError,
    );
  }
}

class SyncEngine extends StateNotifier<SyncStatusState> {
  final DatabaseHelper _dbHelper;
  final Dio _dio;
  static const String _backendBaseUrl = 'http://10.0.2.2:8000'; // Android emulator localhost

  SyncEngine({DatabaseHelper? dbHelper, Dio? dio})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _backendBaseUrl,
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
              ),
            ),
        super(const SyncStatusState()) {
    checkPendingCount();
  }

  Future<int> checkPendingCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'PENDING'",
      );
      final count = (result.isNotEmpty && result.first['count'] != null)
          ? result.first['count'] as int
          : 0;

      state = state.copyWith(pendingCount: count);
      return count;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> syncNow({String? businessId}) async {
    if (state.isSyncing) return false;

    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      // 1. Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult.any(
        (c) => c == ConnectivityResult.mobile || c == ConnectivityResult.wifi,
      );

      if (!hasConnection) {
        state = state.copyWith(
          isSyncing: false,
          isOnline: false,
          lastError: 'Device is offline. Queued for auto-sync.',
        );
        return false;
      }

      state = state.copyWith(isOnline: true);

      // 2. Fetch pending queue items
      final db = await _dbHelper.database;
      final pendingRows = await db.query(
        'sync_queue',
        where: "status = 'PENDING'",
        orderBy: 'created_at ASC',
        limit: 50,
      );

      if (pendingRows.isEmpty) {
        state = state.copyWith(
          isSyncing: false,
          pendingCount: 0,
          lastSyncedAt: DateTime.now(),
        );
        return true;
      }

      // 3. Format items into payload
      final bizId = businessId ?? (pendingRows.first['business_id'] as String? ?? 'default');
      final items = pendingRows.map((r) {
        return {
          'id': r['id'],
          'business_id': r['business_id'],
          'entity_type': r['entity_type'],
          'entity_id': r['entity_id'],
          'operation': r['operation'],
          'payload_json': r['payload_json'],
          'created_at': r['created_at'],
        };
      }).toList();

      // 4. Send batch to backend
      try {
        final response = await _dio.post(
          '/api/v1/sync',
          data: jsonEncode({
            'business_id': bizId,
            'items': items,
          }),
        );

        if (response.statusCode == 200) {
          // 5. Mark synced
          final ids = pendingRows.map((r) => r['id'] as String).toList();
          final placeholders = List.filled(ids.length, '?').join(',');

          await db.rawUpdate(
            "UPDATE sync_queue SET status = 'SYNCED' WHERE id IN ($placeholders)",
            ids,
          );

          final remaining = await checkPendingCount();
          state = state.copyWith(
            isSyncing: false,
            pendingCount: remaining,
            lastSyncedAt: DateTime.now(),
          );
          return true;
        }
      } catch (dioError) {
        // Backend not reachable or local development offline
        final now = DateTime.now().millisecondsSinceEpoch;
        final ids = pendingRows.map((r) => r['id'] as String).toList();
        final placeholders = List.filled(ids.length, '?').join(',');

        await db.rawUpdate(
          "UPDATE sync_queue SET retry_count = retry_count + 1, last_attempt = ? WHERE id IN ($placeholders)",
          [now, ...ids],
        );

        state = state.copyWith(
          isSyncing: false,
          lastError: 'Local sync server unreachable. Changes safely saved offline.',
        );
        return false;
      }

      state = state.copyWith(isSyncing: false);
      return false;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
      return false;
    }
  }
}

final syncEngineProvider =
    StateNotifierProvider<SyncEngine, SyncStatusState>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return SyncEngine(dbHelper: dbHelper);
});
