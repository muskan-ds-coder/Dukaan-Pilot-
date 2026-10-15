import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dukaanpilot_ai/core/utils/currency_formatter.dart';
import 'package:dukaanpilot_ai/data/sync/sync_engine.dart';

void main() {
  group('Phase 5 — Offline-First Sync Queue & Cloud Integration Tests', () {
    test('SyncStatusState preserves immutable state transitions', () {
      const initial = SyncStatusState();
      expect(initial.isSyncing, isFalse);
      expect(initial.pendingCount, 0);
      expect(initial.isOnline, isTrue);

      final syncingState = initial.copyWith(
        isSyncing: true,
        pendingCount: 7,
      );
      expect(syncingState.isSyncing, isTrue);
      expect(syncingState.pendingCount, 7);

      final completedState = syncingState.copyWith(
        isSyncing: false,
        pendingCount: 0,
        lastSyncedAt: DateTime(2026, 10, 15, 18, 0),
      );
      expect(completedState.isSyncing, isFalse);
      expect(completedState.pendingCount, 0);
      expect(completedState.lastSyncedAt, isNotNull);
    });

    test('Validates Sync Item payload JSON serialization integrity', () {
      final item = {
        'id': 'sync-op-101',
        'business_id': 'biz-cosmetics-01',
        'entity_type': 'sale',
        'entity_id': 'sale-8821',
        'operation': 'INSERT',
        'payload_json': jsonEncode({
          'total_paise': 150000,
          'customer_id': 'cust-1',
          'items_count': 3,
        }),
        'created_at': DateTime(2026, 10, 15).millisecondsSinceEpoch,
      };

      final serialized = jsonEncode(item);
      final decoded = jsonDecode(serialized) as Map<String, dynamic>;

      expect(decoded['id'], 'sync-op-101');
      expect(decoded['entity_type'], 'sale');
      expect(decoded['operation'], 'INSERT');

      final nestedPayload = jsonDecode(decoded['payload_json'] as String);
      expect(nestedPayload['total_paise'], 150000);
      expect(nestedPayload['items_count'], 3);
    });

    test('Validates notification briefing and alert financial string accuracy', () {
      const todaySalesPaise = 2450000; // ₹24,500.00
      const pendingUdhaarPaise = 850000; // ₹8,500.00

      final formattedSales = CurrencyFormatter.formatPaise(todaySalesPaise);
      final formattedUdhaar = CurrencyFormatter.formatPaise(pendingUdhaarPaise);

      expect(formattedSales, '₹24,500');
      expect(formattedUdhaar, '₹8,500');

      final notificationTitle = 'Daily Store Summary: $formattedSales Today';
      expect(notificationTitle, contains('₹24,500'));
    });
  });
}
