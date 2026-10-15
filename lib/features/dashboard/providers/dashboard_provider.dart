import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';

class DashboardMetrics {
  final int todaySalesPaise;
  final int todayPurchasesPaise;
  final int todayExpensesPaise;
  final int outstandingUdhaarPaise;
  final int lowStockCount;
  final int todayTransactionCount;
  final bool hasAnyData;

  const DashboardMetrics({
    required this.todaySalesPaise,
    required this.todayPurchasesPaise,
    required this.todayExpensesPaise,
    required this.outstandingUdhaarPaise,
    required this.lowStockCount,
    required this.todayTransactionCount,
    required this.hasAnyData,
  });

  factory DashboardMetrics.empty() => const DashboardMetrics(
        todaySalesPaise: 0,
        todayPurchasesPaise: 0,
        todayExpensesPaise: 0,
        outstandingUdhaarPaise: 0,
        lowStockCount: 0,
        todayTransactionCount: 0,
        hasAnyData: false,
      );
}

final dashboardMetricsProvider = FutureProvider.autoDispose<DashboardMetrics>((ref) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  final db = await dbHelper.database;
  final saleRepo = ref.watch(saleRepositoryProvider);
  final custRepo = ref.watch(customerRepositoryProvider);
  final prodRepo = ref.watch(productRepositoryProvider);

  final todaySales = await saleRepo.getTodaySalesTotal();
  final txCount = await saleRepo.getTodayTransactionCount();
  final udhaar = await custRepo.getTotalOutstandingUdhaar();
  final lowStockList = await prodRepo.getLowStockProducts();

  // Today Expenses
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  final expResult = await db.rawQuery(
    'SELECT SUM(amount_paise) as total FROM expenses WHERE date >= ?',
    [startOfDay],
  );
  final todayExpenses = (expResult.isNotEmpty && expResult.first['total'] != null)
      ? expResult.first['total'] as int
      : 0;

  // Today Purchases
  final purResult = await db.rawQuery(
    'SELECT SUM(total_paise) as total FROM purchases WHERE date >= ?',
    [startOfDay],
  );
  final todayPurchases = (purResult.isNotEmpty && purResult.first['total'] != null)
      ? purResult.first['total'] as int
      : 0;

  // Check if any product exists
  final totalProdCount = await db.rawQuery('SELECT COUNT(*) as count FROM products WHERE is_active = 1');
  final hasProducts = (totalProdCount.isNotEmpty && (totalProdCount.first['count'] as int? ?? 0) > 0);

  return DashboardMetrics(
    todaySalesPaise: todaySales,
    todayPurchasesPaise: todayPurchases,
    todayExpensesPaise: todayExpenses,
    outstandingUdhaarPaise: udhaar,
    lowStockCount: lowStockList.length,
    todayTransactionCount: txCount,
    hasAnyData: hasProducts || todaySales > 0 || udhaar > 0,
  );
});

final todaySalesTotalProvider = FutureProvider.autoDispose<int>((ref) async {
  final metrics = await ref.watch(dashboardMetricsProvider.future);
  return metrics.todaySalesPaise;
});

final todayTransactionsProvider = FutureProvider.autoDispose<int>((ref) async {
  final metrics = await ref.watch(dashboardMetricsProvider.future);
  return metrics.todayTransactionCount;
});

final todayNetCashProvider = FutureProvider.autoDispose<int>((ref) async {
  final metrics = await ref.watch(dashboardMetricsProvider.future);
  return metrics.todaySalesPaise - metrics.todayExpensesPaise;
});

final lowStockCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final metrics = await ref.watch(dashboardMetricsProvider.future);
  return metrics.lowStockCount;
});

final totalUdhaarProvider = FutureProvider.autoDispose<int>((ref) async {
  final metrics = await ref.watch(dashboardMetricsProvider.future);
  return metrics.outstandingUdhaarPaise;
});

